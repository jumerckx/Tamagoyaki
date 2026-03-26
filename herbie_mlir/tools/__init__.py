from xdsl.ir import (
    Attribute,
    Dialect,
    EnumAttribute,
    SpacedOpaqueSyntaxAttribute,
    StrEnum,
)
from xdsl.irdl import (
    IRDLOperation,
    irdl_attr_definition,
    irdl_op_definition,
    prop_def,
    result_def,
)
from xdsl.universe import Universe

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

EQSAT_UNIVERSE = Universe(all_dialects={"herbie": lambda: Herbie})
