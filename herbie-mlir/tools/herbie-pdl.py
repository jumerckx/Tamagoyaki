# /// script
# requires-python = ">=3.10"
# dependencies = ["xdsl", "mpmath"]
# ///
"""Convert Herbie rewrite rules (S-expression .rkt files) to PDL MLIR dialect."""

import argparse
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Union

from xdsl.builder import Builder
from xdsl.dialects import pdl
from xdsl.dialects.builtin import (
    AnyFloat,
    AnySignlessIntegerType,
    ArrayAttr,
    FloatAttr,
    IntegerAttr,
    IntegerType,
    StringAttr,
    f32,
)
from xdsl.ir import (
    Attribute,
    Dialect,
    EnumAttribute,
    SpacedOpaqueSyntaxAttribute,
    SSAValue,
)
from xdsl.ir.core import OpResult
from xdsl.irdl import (
    IRDLOperation,
    irdl_attr_definition,
    irdl_op_definition,
    prop_def,
    result_def,
)
from xdsl.utils.str_enum import StrEnum

# --- Data types ---


@dataclass(frozen=True)
class Operand:
    name: str
    constraints: list[str] = field(default_factory=list)


@dataclass
class Literal:
    value: str


@dataclass
class Operation:
    name: str
    operands: Sequence[Union["Operand", "Operation", "Literal"]]
    constraints: list[str] = field(default_factory=list)


Expr = Operation | Operand | Literal


@dataclass
class Rule:
    name: str
    original: Expr
    rewritten: Expr
    operands: dict[str, set[str]]

    def __init__(self, name: str, original: Expr, rewritten: Expr):
        self.name = name
        self.original = original
        self.rewritten = rewritten
        orig_ops = _collect_operands(original)
        rewr_ops = _collect_operands(rewritten)
        undefined = rewr_ops.keys() - orig_ops.keys()
        if undefined:
            raise ValueError(f"Rule '{name}' uses undefined operands: {undefined}")
        self.operands = orig_ops


@dataclass
class RuleSet:
    name: str
    rules: list[Rule]


def _collect_operands(expr: Expr) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    work = [expr]
    while work:
        cur = work.pop()
        if isinstance(cur, Operand):
            result.setdefault(cur.name, set()).update(cur.constraints)
        elif isinstance(cur, Operation):
            work.extend(cur.operands)
    return result


# --- S-expression parser ---


def parse_rewrite_rules(text: str) -> list[RuleSet]:
    text = re.sub(r";[^\n]*", "", text)
    tokens = re.findall(r"[()[\]]|[^\s()[\]]+", text)
    pos = [0]

    def peek() -> str:
        return tokens[pos[0]] if pos[0] < len(tokens) else ""

    def consume() -> str:
        t = tokens[pos[0]]
        pos[0] += 1
        return t

    def is_number(t: str) -> bool:
        try:
            float(t)
            return True
        except ValueError:
            if "/" in t and t.count("/") == 1:
                a, b = t.split("/")
                try:
                    float(a)
                    float(b)
                    return True
                except ValueError:
                    pass
            return False

    def parse_expr() -> Expr:
        if peek() == "(":
            consume()
            name = consume()
            ops: list[Expr] = []
            while peek() != ")":
                ops.append(parse_expr())
            consume()
            return Operation(name, ops)
        t = peek()
        if is_number(t):
            consume()
            return Literal(t)
        consume()
        return Operand(t)

    def parse_rule() -> Rule:
        consume()  # [
        name = consume()
        orig = parse_expr()
        rewr = parse_expr()
        while peek() not in ("]", ""):
            consume()  # skip flags like #:unsound
        consume()  # ]
        return Rule(name, orig, rewr)

    rulesets: list[RuleSet] = []
    while pos[0] < len(tokens):
        consume()  # (
        assert consume() == "define-rules"
        name = consume()
        rules: list[Rule] = []
        while peek() != ")":
            rules.append(parse_rule())
        consume()  # )
        rulesets.append(RuleSet(name, rules))
    return rulesets


# --- PDL conversion ---

OPERATION_MAP = {
    "+": "arith.addf",
    "-": "arith.subf",
    "*": "arith.mulf",
    "/": "arith.divf",
    "remainder": "arith.remf",
    "neg": "arith.negf",
    "fabs": "math.absf",
    "copysign": "math.copysign",
    "pow": "math.powf",
    "sqrt": "math.sqrt",
    "cbrt": "math.cbrt",
    "log": "math.log",
    "exp": "math.exp",
    "sin": "math.sin",
    "cos": "math.cos",
    "tan": "math.tan",
    "asin": "math.asin",
    "acos": "math.acos",
    "atan": "math.atan",
    "atan2": "math.atan2",
    "sinh": "math.sinh",
    "cosh": "math.cosh",
    "tanh": "math.tanh",
    "asinh": "math.asinh",
    "acosh": "math.acosh",
    "atanh": "math.atanh",
    "sound-/": "herbie.sound_div",
    "sound-pow": "herbie.sound_pow",
    "sound-log": "herbie.sound_log",
}


def _sanitize(name: str) -> str:
    s = (
        name.replace("--", "sub_")
        .replace("+", "add")
        .replace("*", "mul")
        .replace("/", "div")
        .replace("-", "_")
    )
    return ("_" + s) if s[0].isdigit() else s


def _parse_float(s: str) -> float:
    """Parse a float literal, handling fractions like '1/2'."""
    if "/" in s and s.count("/") == 1:
        num, den = s.split("/")
        return float(num) / float(den)
    return float(s)


def _build_expr(
    expr: Expr,
    vals: dict[str, SSAValue],
    etype: AnyFloat | IntegerType | None,
    tvar: OpResult[pdl.TypeType],
) -> SSAValue:
    if isinstance(expr, Operand):
        return vals[expr.name]

    if isinstance(expr, Literal):
        if isinstance(etype, IntegerType):
            attr = pdl.AttributeOp(IntegerAttr(int(expr.value), etype))
        elif isinstance(etype, AnyFloat):
            fval = _parse_float(expr.value)
            attr = pdl.AttributeOp(FloatAttr(fval, etype))
        else:
            raise ValueError(f"Unsupported type: {type(etype)}")
        op = pdl.OperationOp(
            op_name="arith.constant",
            attribute_value_names=ArrayAttr([StringAttr("value")]),
            attribute_values=(attr.output,),
            type_values=(tvar,),
        )
        return pdl.ResultOp(IntegerAttr.from_int_and_width(0, 32), op.results[0]).val

    assert isinstance(expr, Operation)
    if expr.name in Constant.__members__ and not expr.operands:
        attr = pdl.AttributeOp(ConstantAttr(Constant[expr.name]))
        op = pdl.OperationOp(
            op_name="herbie.constant",
            attribute_value_names=(StringAttr("symbol"),),
            attribute_values=(attr.output,),
            type_values=(tvar,),
        )
    else:
        mlir_name = OPERATION_MAP.get(expr.name, expr.name)
        operands = [_build_expr(o, vals, etype, tvar) for o in expr.operands]
        op = pdl.OperationOp(
            op_name=mlir_name, operand_values=operands, type_values=(tvar,)
        )
    return pdl.ResultOp(IntegerAttr.from_int_and_width(0, 32), op.results[0]).val


def convert_rule(
    rule: Rule,
    element_type: AnyFloat | AnySignlessIntegerType = f32,
    benefit: int = 1,
) -> pdl.PatternOp:
    vals: dict[str, SSAValue] = {}

    @Builder.implicit_region
    def body() -> None:
        tvar = pdl.TypeOp(element_type).result
        for name, constraints in rule.operands.items():
            v = pdl.OperandOp(tvar).value
            v.name_hint = name
            for c in constraints:
                pdl.ApplyNativeConstraintOp(c, (v,), ())
            vals[name] = v

        root_val = _build_expr(rule.original, vals, element_type, tvar)
        assert isinstance(root_val, OpResult) and isinstance(
            root_val.owner, pdl.ResultOp
        )
        root_op = root_val.owner.parent_

        @Builder.implicit_region
        def rewrite() -> None:
            repl = _build_expr(rule.rewritten, vals, element_type, tvar)
            pdl.ReplaceOp(op_value=root_op, repl_values=[repl])

        pdl.RewriteOp(root=root_op, body=rewrite)

    return pdl.PatternOp(benefit, _sanitize(rule.name), body)


# --- Constants ---

"""
The herbie dialect defines operations and attributes for representing
mathematical constants and expressions in IR, based on the Herbie
numerical analysis tool.

Currently, it contains the `herbie.constant` operation and a related
attribute, which can be used to define and use mathematical constants in IR.
"""


class Constant(StrEnum):
    E = "E"  # 𝑒
    PI = "PI"  # π
    M_2_SQRTPI = "M_2_SQRTPI"  # 2/sqrt(π)
    LOG2E = "LOG2E"  # log2(𝑒)
    PI_2 = "PI_2"  # π/2
    SQRT2 = "SQRT2"  # sqrt(2)
    LOG10E = "LOG10E"  # log10(𝑒)
    PI_4 = "PI_4"  # π/4
    SQRT1_2 = "SQRT1_2"  # sqrt(1/2)
    LN2 = "LN2"  # ln(2)
    M_1_PI = "M_1_PI"  # 1/π
    INFINITY = "INFINITY"  # ∞
    LN10 = "LN10"  # ln(10)
    M_2_PI = "M_2_PI"  # 2/π


@irdl_attr_definition
class ConstantAttr(EnumAttribute[Constant], SpacedOpaqueSyntaxAttribute):
    name = "herbie.constant"


@irdl_op_definition
class ConstantOp(IRDLOperation):
    name = "herbie.constant"

    symbol = prop_def(ConstantAttr)

    value = result_def()

    assembly_format = "$symbol attr-dict `:` type($value)"

    def __init__(self, symbol: Constant | ConstantAttr, result_type: Attribute):
        if not isinstance(symbol, ConstantAttr):
            symbol = ConstantAttr(symbol)
        super().__init__(
            properties={
                "symbol": symbol,
            },
            result_types=[result_type],
        )


Herbie = Dialect(
    "herbie",
    [
        ConstantOp,
    ],
    [
        ConstantAttr,
    ],
)

# --- CLI ---


def main(args: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Convert Herbie rewrite rules to PDL MLIR")
    ap.add_argument("input_file", type=Path, help="Input .rkt file with rewrite rules")
    ap.add_argument(
        "-o", "--output", type=Path, default=None, help="Output file (default: stdout)"
    )
    parsed = ap.parse_args(args)

    if not parsed.input_file.exists():
        print(f"Error: '{parsed.input_file}' not found", file=sys.stderr)
        return 1

    try:
        rulesets = parse_rewrite_rules(parsed.input_file.read_text())
        lines = [str(convert_rule(rule)) for rs in rulesets for rule in rs.rules]
        out = "\n".join(lines)
        if parsed.output:
            parsed.output.write_text(out)
            print(f"Written to '{parsed.output}'")
        else:
            print(out)
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        raise


if __name__ == "__main__":
    sys.exit(main())
