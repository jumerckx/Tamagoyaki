import sys

from herbie_mlir.tools.fpcore_mlir import Constant, FPCore, Operation, Variable
from xdsl import ir
from xdsl.context import Context
from xdsl.dialects import arith, func, math, scf
from xdsl.dialects.builtin import FloatAttr
from xdsl.ir import Block, SSAValue
from xdsl.universe import Universe

# Reverse mappings from MLIR operation types to FPCore operation names
MLIR_TO_FPCORE_BINARY = {
    arith.AddfOp: "+",
    arith.SubfOp: "-",
    arith.MulfOp: "*",
    arith.DivfOp: "/",
    arith.MinnumfOp: "fmin",
    arith.MaximumfOp: "fmax",
    math.PowFOp: "pow",
    math.Atan2Op: "atan2",
}

MLIR_TO_FPCORE_UNARY = {
    arith.NegfOp: "-",
    math.SqrtOp: "sqrt",
    math.ExpOp: "exp",
    math.ExpM1Op: "expm1",
    math.LogOp: "log",
    math.Log1pOp: "log1p",
    math.SinOp: "sin",
    math.CosOp: "cos",
    math.TanOp: "tan",
    math.AtanOp: "atan",
    math.SinhOp: "sinh",
    math.CoshOp: "cosh",
    math.TanhOp: "tanh",
}

MLIR_TO_FPCORE_TERNARY = {
    math.FmaOp: "fma",
}

MLIR_TO_FPCORE_CMP = {
    "olt": "<",
    "ogt": ">",
    "ole": "<=",
    "oge": ">=",
    "oeq": "==",
    "one": "!=",
}


class ConversionContext:
    """Context for tracking SSA values to FPCore expressions during conversion."""

    def __init__(self, parent: "ConversionContext | None" = None):
        self.parent = parent
        self.ssa_to_expr: dict[SSAValue, Operation | Variable | Constant] = {}
        # Map block arguments to variable names
        self.arg_to_var: dict[SSAValue, str] = {}

    def get_expression(self, value: SSAValue) -> Operation | Variable | Constant:
        """Get the FPCore expression for an SSA value."""
        if value in self.ssa_to_expr:
            return self.ssa_to_expr[value]
        if self.parent is not None:
            return self.parent.get_expression(value)
        raise ValueError(f"SSA value not found: {value}")

    def set_expression(self, value: SSAValue, expr: Operation | Variable | Constant):
        """Map an SSA value to an FPCore expression."""
        self.ssa_to_expr[value] = expr

    def has_expression(self, value: SSAValue) -> bool:
        """Check if an SSA value has been converted."""
        if value in self.ssa_to_expr:
            return True
        if self.parent is not None:
            return self.parent.has_expression(value)
        return False


class MLIRToFPCoreConverter:
    """Converts MLIR functions to FPCore representation."""

    def __init__(self, func_op: func.FuncOp):
        self.func_op = func_op

    def convert(self) -> FPCore:
        """Convert an MLIR function to FPCore."""
        block = self.func_op.body.blocks[0]

        # Create argument names
        arguments = [f"arg{i}" for i in range(len(block.args))]

        # Create a context for this function
        context = ConversionContext()

        # Map block arguments to variable names
        for i, arg in enumerate(block.args):
            context.arg_to_var[arg] = arguments[i]

        # Find the return operation and work backwards
        result_expr = self._process_block(block, context)

        # Extract function name and convert underscores back to spaces
        func_name = self.func_op.sym_name.data.replace("_", " ")

        return FPCore(
            name=func_name,
            arguments=arguments,
            properties={":name": f'"{func_name}"'},
            expression=result_expr,
        )

    def _process_block(
        self, block: Block, context: ConversionContext
    ) -> Operation | Variable | Constant:
        """Process a block by finding the return/yield and working backwards."""
        # Find the terminator operation (return or yield)
        terminator = block.last_op

        if isinstance(terminator, (func.ReturnOp, scf.YieldOp)):
            # Convert the returned value (this will recursively convert dependencies)
            return self._convert_value(terminator.operands[0], context)

        raise ValueError("No return or yield operation found")

    def _convert_value(
        self, value: SSAValue, context: ConversionContext
    ) -> Operation | Variable | Constant:
        """Convert an SSA value to FPCore expression, recursively processing dependencies."""
        # Check if already converted (memoization)
        if context.has_expression(value):
            return context.get_expression(value)

        # Check if this is a block argument (function parameter)
        if value in context.arg_to_var:
            var = Variable(context.arg_to_var[value])
            context.set_expression(value, var)
            return var

        # Otherwise, it must be defined by an operation
        defining_op = value.owner
        if not isinstance(defining_op, ir.Operation):
            raise ValueError(f"SSA value has no defining operation: {value}")

        # Convert the defining operation
        expr = self._convert_operation(defining_op, context)
        context.set_expression(value, expr)
        return expr

    def _convert_operation(
        self, op: ir.Operation, context: ConversionContext
    ) -> Operation | Variable | Constant:
        """Convert a single MLIR operation to FPCore expression."""
        if isinstance(op, arith.ConstantOp):
            # Handle constant operations
            attr = op.value
            if isinstance(attr, FloatAttr):
                value = attr.value.data
                return Constant(value)
            else:
                raise NotImplementedError(f"Unsupported constant type: {type(attr)}")

        # Binary operations
        elif type(op) in MLIR_TO_FPCORE_BINARY:
            fpcore_name = MLIR_TO_FPCORE_BINARY[type(op)]  # pyright: ignore[reportArgumentType]
            # Recursively convert operands
            lhs = self._convert_value(op.operands[0], context)
            rhs = self._convert_value(op.operands[1], context)
            return Operation(fpcore_name, [lhs, rhs])

        elif isinstance(op, math.CbrtOp):
            operand = self._convert_value(op.operands[0], context)
            # Create (/ 1 3)
            one_third = Operation("/", [Constant(1), Constant(3)])
            return Operation("pow", [operand, one_third])

        # Unary operations
        elif type(op) in MLIR_TO_FPCORE_UNARY:
            fpcore_name = MLIR_TO_FPCORE_UNARY[type(op)]  # pyright: ignore[reportArgumentType]
            # Recursively convert operand
            operand = self._convert_value(op.operands[0], context)
            return Operation(fpcore_name, [operand])

        # Ternary operations
        elif type(op) in MLIR_TO_FPCORE_TERNARY:
            fpcore_name = MLIR_TO_FPCORE_TERNARY[type(op)]  # pyright: ignore[reportArgumentType]
            # Recursively convert operands
            operand1 = self._convert_value(op.operands[0], context)
            operand2 = self._convert_value(op.operands[1], context)
            operand3 = self._convert_value(op.operands[2], context)
            return Operation(fpcore_name, [operand1, operand2, operand3])

        else:
            raise NotImplementedError(
                f"Unsupported operation type: {type(op).__name__}"
            )


def convert_mlir_to_fpcore(func_op: func.FuncOp) -> FPCore:
    """Convert an MLIR function to FPCore representation."""
    converter = MLIRToFPCoreConverter(func_op)
    return converter.convert()


def fpcore_to_string(fpcore: FPCore) -> str:
    """Convert an FPCore object to its string representation."""

    def expr_to_string(expr: Operation | Variable | Constant) -> str:
        if isinstance(expr, Variable):
            return expr.name
        elif isinstance(expr, Constant):
            if isinstance(expr.value, str):
                value = expr.value
                # Return as-is if it's already a constant name or quoted string
                return value
            # Format numbers
            return str(expr.value)
        else:  # Operation
            operands_str = " ".join(expr_to_string(op) for op in expr.operands)
            return f"({expr.name} {operands_str})"

    # Build the FPCore string
    args = " ".join(fpcore.arguments)
    expr_str = expr_to_string(fpcore.expression)

    # Build properties string
    props_parts: list[str] = []
    for key, value in fpcore.properties.items():
        props_parts.append(f"{key} {value}")
    props_str = " ".join(props_parts)

    if props_str:
        return f"(FPCore ({args}) {props_str} {expr_str})"
    else:
        return f"(FPCore ({args}) {expr_str})"


def main():
    from xdsl.parser import Parser

    # Read from file if provided, otherwise from stdin
    if len(sys.argv) > 2:
        print("Usage: python generator.py [mlir_file]")
        print("  If no file is provided, reads from stdin")
        return

    if len(sys.argv) == 2:
        mlir_file = sys.argv[1]
        with open(mlir_file) as f:
            mlir_content = f.read()
    else:
        # Read from stdin
        mlir_content = sys.stdin.read()

    # Parse the MLIR content
    ctx = Context()
    multiverse = Universe.get_multiverse()
    for dialect_name, dialect_factory in multiverse.all_dialects.items():
        ctx.register_dialect(dialect_name, dialect_factory)

    module = Parser(ctx, mlir_content).parse_module()

    # Convert each function in the module to FPCore and print
    for op in module.ops:
        if isinstance(op, func.FuncOp):
            fpcore = convert_mlir_to_fpcore(op)
            fpcore_str = fpcore_to_string(fpcore)
            print(fpcore_str)


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
