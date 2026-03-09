import argparse
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from typing import Union

from xdsl import ir
from xdsl.builder import Builder
from xdsl.dialects import arith, func, math, scf
from xdsl.dialects.builtin import AnyFloat, FloatAttr, FunctionType, ModuleOp, f32, i1
from xdsl.ir import Block, Region, SSAValue
from xdsl.printer import Printer
from xdsl.rewriter import InsertPoint

# ============================================================================
# Parser
# ============================================================================


@dataclass
class Variable:
    name: str

    def __repr__(self):
        return f"Variable({self.name})"


@dataclass
class Constant:
    value: int | float | str

    def __repr__(self):
        if isinstance(self.value, str):
            return f'Constant("{self.value}")'
        return f"Constant({self.value})"


@dataclass
class Operation:
    name: str
    operands: Sequence[Union["Operation", "Variable", "Constant"]]

    def __repr__(self):
        return f"Operation({self.name}, {list(self.operands)})"


@dataclass
class FPCore:
    name: str
    arguments: list[str]
    properties: dict[str, str]
    expression: Operation | Variable | Constant

    def __repr__(self):
        return f"FPCore({self.name}, args={self.arguments}, expr={self.expression})"


class FPCoreParser:
    def __init__(self, text: str):
        self.tokens = self._tokenize(text)
        self.pos = 0

    def _tokenize(self, text: str) -> list[str]:
        # Remove comments
        text = re.sub(r";[^\n]*", "", text)
        # Split on all delimiters (parentheses, quotes, whitespace), keeping delimiters
        tokens = re.findall(r'[()]|"[^"]*"|[^\s()]+', text)
        return [t for t in tokens if t.strip()]

    def _peek(self) -> str:
        if self.pos >= len(self.tokens):
            return ""
        return self.tokens[self.pos]

    def _consume(self) -> str:
        if self.pos >= len(self.tokens):
            raise ValueError("Unexpected end of input")
        token = self.tokens[self.pos]
        self.pos += 1
        return token

    def _is_number(self, token: str) -> bool:
        try:
            float(token)
            return True
        except ValueError:
            # Check if it's a fraction like "1/2"
            if "/" in token and token.count("/") == 1:
                parts = token.split("/")
                if len(parts) == 2:
                    try:
                        float(parts[0])
                        float(parts[1])
                        return True
                    except ValueError:
                        pass
            return False

    def _parse_number(self, token: str) -> int | float:
        """Parse a number token into int or float."""
        if "/" in token and token.count("/") == 1:
            # Handle fractions like "1/2"
            parts = token.split("/")
            if len(parts) == 2:
                try:
                    numerator = float(parts[0])
                    denominator = float(parts[1])
                    if denominator == 0:
                        raise ValueError(f"Division by zero in fraction: {token}")
                    return numerator / denominator
                except ValueError:
                    pass

        if "." in token:
            return float(token)
        else:
            return int(token)

    def _parse_expression(self) -> Operation | Variable | Constant:
        if self._peek() == "(":
            return self._parse_operation()
        else:
            token = self._peek()
            if self._is_number(token):
                value = self._parse_number(self._consume())
                return Constant(value)
            elif token.startswith('"'):
                return Constant(self._consume())
            else:
                supported_constants = {
                    "E",
                    "LOG2E",
                    "LOG10E",
                    "LN2",
                    "LN10",
                    "PI",
                    "PI_2",
                    "PI_4",
                    "M_1_PI",
                    "M_2_PI",
                    "M_2_SQRTPI",
                    "SQRT2",
                    "SQRT1_2",
                    "INFINITY",
                    "NAN",
                    "TRUE",
                    "FALSE",
                }
                if token in supported_constants:
                    return Constant(self._consume())
                else:
                    return Variable(self._consume())

    def _parse_operation(self) -> Operation:
        self._consume()  # consume '('

        if self.pos >= len(self.tokens):
            raise ValueError("Unexpected end of input in operation")

        name = self._consume()
        operands: list[Operation | Variable | Constant] = []

        while self._peek() != ")":
            if not self._peek():
                raise ValueError("Unclosed operation")
            operands.append(self._parse_expression())

        self._consume()  # consume ')'
        return Operation(name, operands)

    def _parse_property_value(self) -> str:
        if self._peek() != "(":
            return self._consume()

        self._consume()  # consume '('
        tokens: list[str] = []
        paren_level = 1
        while self.pos < len(self.tokens) and paren_level > 0:
            token = self._consume()
            if token == "(":
                paren_level += 1
            elif token == ")":
                paren_level -= 1
            tokens.append(token)

        if paren_level > 0:
            raise ValueError("Unclosed parenthesis in property value")

        # Return the full s-expression as a string, including outer parens
        return f"({' '.join(tokens[:-1])})"

    def parse_one(self) -> FPCore:
        self._consume()  # consume '('
        if self._consume() != "FPCore":
            raise ValueError("Expected 'FPCore'")

        # Parse arguments
        self._consume()  # consume '('
        arguments: list[str] = []
        while self._peek() != ")":
            arguments.append(self._consume())
        self._consume()  # consume ')'

        # Parse properties
        properties: dict[str, str] = {}
        while self._peek().startswith(":"):
            key = self._consume()
            properties[key] = self._parse_property_value()

        # Parse expression body
        expression = self._parse_expression()

        self._consume()  # consume ')'

        return FPCore(
            name=properties.get(":name", "unnamed"),
            arguments=arguments,
            properties=properties,
            expression=expression,
        )

    def parse(self) -> list[FPCore]:
        cores: list[FPCore] = []
        while self._peek() == "(":
            cores.append(self.parse_one())
        return cores


def parse_fpcore(text: str) -> list[FPCore]:
    """High-level function to parse an FPCore string."""
    parser = FPCoreParser(text)
    return parser.parse()


# ============================================================================
# Generator
# ============================================================================

# Mapping from FPCore operation names to MLIR operations for binary operations
BINARY_OPERATION_MAP = {
    # Arithmetic operations
    "+": arith.AddfOp,
    "-": arith.SubfOp,
    "*": arith.MulfOp,
    "/": arith.DivfOp,
    "fmin": arith.MinnumfOp,
    "fmax": arith.MaximumfOp,
    # Math functions
    "pow": math.PowFOp,
}

# Mapping from FPCore operation names to MLIR operations for unary operations
UNARY_OPERATION_MAP = {
    # Arithmetic operations
    "neg": arith.NegfOp,
    "-": arith.NegfOp,  # Unary negation
    # Math functions
    "sqrt": math.SqrtOp,
    "exp": math.ExpOp,
    "log": math.LogOp,
    "sin": math.SinOp,
    "cos": math.CosOp,
    "tan": math.TanOp,
    "atan": math.AtanOp,
}

# Mapping from FPCore comparison names to the string representation of arith.cmpf  attributes
CMP_MAP = {
    "<": "olt",
    ">": "ogt",
    "<=": "ole",
    ">=": "oge",
    "==": "oeq",
    "!=": "one",
}


class MLIRGenerator:
    def __init__(self, fpcore: FPCore, float_type: AnyFloat = f32):
        self.fpcore = fpcore
        self.float_type = float_type
        self.ssa_map: dict[str, SSAValue] = {}

    def generate_function(self) -> func.FuncOp:
        """Generate an MLIR function from the FPCore expression."""

        # Create the function type
        arg_types = [self.float_type] * len(self.fpcore.arguments)
        func_type = FunctionType.from_lists(arg_types, [self.float_type])

        # Sanitize the function name
        func_name = self.fpcore.name.strip('"').replace(" ", "_").replace("-", "_")
        if not func_name:
            func_name = "fpcore_func"

        # Create the function operation
        block = Block(arg_types=arg_types)
        region = Region([block])
        func_op = func.FuncOp(func_name, func_type, region)

        # Map function arguments to variable names
        for i, arg_name in enumerate(self.fpcore.arguments):
            self.ssa_map[arg_name] = block.args[i]

        builder = Builder(InsertPoint.at_end(block))
        result = self._build_expression(self.fpcore.expression, builder)
        builder.insert(func.ReturnOp(result))

        return func_op

    def _build_expression(
        self, expr: Operation | Variable | Constant, builder: Builder
    ) -> SSAValue:
        """Recursively build an MLIR expression from an FPCore AST node."""
        if isinstance(expr, Variable):
            if expr.name not in self.ssa_map:
                raise ValueError(f"Undefined variable: {expr.name}")
            return self.ssa_map[expr.name]

        elif isinstance(expr, Constant):
            if isinstance(expr.value, int | float):
                attr = FloatAttr(float(expr.value), self.float_type)
                op = arith.ConstantOp(attr)
                builder.insert(op)
                return op.result
            else:
                if expr.value == "PI":
                    attr = FloatAttr(3.141592653589793, self.float_type)
                    op = arith.ConstantOp(attr)
                    builder.insert(op)
                    return op.result
                raise NotImplementedError(f"Unsupported constant: {expr.value}")

        else:
            assert isinstance(expr, Operation)
            # Handle 'if' separately as it's a control flow operation
            if expr.name == "if":
                if len(expr.operands) != 3:
                    raise ValueError(
                        "If expression expects 3 operands (condition, true, false), "
                        f"but got {len(expr.operands)}"
                    )

                original_insert_point = builder.insertion_point

                # 1. Build the condition in the current block.
                cond_val = self._build_expression(expr.operands[0], builder)
                if cond_val.type != i1:
                    raise TypeError(
                        f"If condition must be a boolean (i1), but got {cond_val.type}"
                    )

                # 2. Build the 'then' (true) region.
                true_region = Region(Block())
                builder.insertion_point = InsertPoint.at_start(true_region.block)
                true_result = self._build_expression(expr.operands[1], builder)
                builder.insert(scf.YieldOp(true_result))

                # 3. Build the 'else' (false) region.
                false_region = Region(Block())
                builder.insertion_point = InsertPoint.at_start(false_region.block)
                false_result = self._build_expression(expr.operands[2], builder)
                builder.insert(scf.YieldOp(false_result))

                if true_result.type != false_result.type:
                    raise TypeError(
                        "Mismatched types in if expression branches: "
                        f"{true_result.type} vs {false_result.type}"
                    )

                # 4. Restore builder and insert the scf.if operation.
                builder.insertion_point = original_insert_point
                if_op = scf.IfOp(
                    cond_val, [true_result.type], true_region, false_region
                )
                builder.insert(if_op)
                return if_op.results[0]

            # Handle comparison operations that produce the condition for 'if'
            elif expr.name in CMP_MAP:
                if len(expr.operands) != 2:
                    raise NotImplementedError(
                        f"Only binary comparison '{expr.name}' is supported, "
                        f"but got {len(expr.operands)} operands."
                    )
                operands = [self._build_expression(op, builder) for op in expr.operands]
                predicate = CMP_MAP[expr.name]
                op = arith.CmpfOp(operands[0], operands[1], predicate)
                builder.insert(op)
                return op.result

            # Handle operations based on number of operands
            else:
                num_operands = len(expr.operands)

                if num_operands == 1:
                    # Check for unary operations
                    if expr.name == "+":
                        # Unary plus is a no-op, just return the operand
                        return self._build_expression(expr.operands[0], builder)
                    elif expr.name in UNARY_OPERATION_MAP:
                        op_class = UNARY_OPERATION_MAP[expr.name]
                        operand = self._build_expression(expr.operands[0], builder)
                        op = op_class(operand)
                        builder.insert(op)
                        return op.results[0]
                    else:
                        raise NotImplementedError(
                            f"Unsupported unary operation: {expr.name}"
                        )

                elif num_operands == 2:
                    # Check for binary operations
                    if expr.name in BINARY_OPERATION_MAP:
                        op_class = BINARY_OPERATION_MAP[expr.name]
                        operands = [
                            self._build_expression(op, builder) for op in expr.operands
                        ]
                        op = op_class(operands[0], operands[1])
                        builder.insert(op)
                        return op.results[0]
                    else:
                        raise NotImplementedError(
                            f"Unsupported binary operation: {expr.name}"
                        )

                elif num_operands > 2:
                    # Handle n-ary operations by chaining binary operations
                    if expr.name in BINARY_OPERATION_MAP:
                        op_class = BINARY_OPERATION_MAP[expr.name]
                        result = self._build_expression(expr.operands[0], builder)
                        for operand_expr in expr.operands[1:]:
                            operand = self._build_expression(operand_expr, builder)
                            op = op_class(result, operand)
                            builder.insert(op)
                            result = op.results[0]
                        return result
                    else:
                        raise NotImplementedError(
                            f"Unsupported n-ary operation: {expr.name}"
                        )

                else:
                    raise ValueError(f"Operation '{expr.name}' has no operands")


def generate_mlir_from_fpcore(text: str, float_type: AnyFloat = f32) -> ModuleOp:
    """High-level function to parse FPCore and generate MLIR."""
    fpcore_objs = parse_fpcore(text)
    functions: list[ir.Operation] = []
    for fpcore_obj in fpcore_objs:
        generator = MLIRGenerator(fpcore_obj, float_type)
        functions.append(generator.generate_function())

    module = ModuleOp(functions)
    return module


# ============================================================================
# CLI
# ============================================================================


def main(args: list[str] | None = None) -> int:
    """Main entry point for fpcore-mlir CLI."""
    parser = argparse.ArgumentParser(description="Convert FPCore files to MLIR")
    parser.add_argument(
        "input_file",
        help="Input file containing FPCore expressions",
        type=Path,
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output file (default: stdout)",
        type=Path,
        default=None,
    )

    parsed_args = parser.parse_args(args)

    # Check if input file exists
    if not parsed_args.input_file.exists():
        print(
            f"Error: Input file '{parsed_args.input_file}' does not exist",
            file=sys.stderr,
        )
        return 1

    try:
        # Read the input file
        with open(parsed_args.input_file) as f:
            content = f.read()

        # Generate MLIR
        mlir_module = generate_mlir_from_fpcore(content)

        # Print the MLIR
        output_str = StringIO()
        printer = Printer(stream=output_str)
        printer.print_op(mlir_module)

        # Write output
        if parsed_args.output:
            with open(parsed_args.output, "w") as f:
                f.write(output_str.getvalue())
            print(f"MLIR written to '{parsed_args.output}'")
        else:
            print(output_str.getvalue())

        return 0

    except Exception as e:
        print(f"Error processing file: {e}", file=sys.stderr)
        return 1


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
