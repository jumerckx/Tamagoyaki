import argparse
import sys
from pathlib import Path
from typing import TypeAlias

# S-expression type: either a string (atom) or a list of S-expressions
SExpr: TypeAlias = str | list["SExpr"]


def tokenize(text: str) -> list[str]:
    """Tokenize S-expression, preserving strings and handling parens."""
    tokens: list[str] = []
    i = 0
    while i < len(text):
        # Skip whitespace
        if text[i].isspace():
            i += 1
            continue

        # Handle strings
        if text[i] == '"':
            j = i + 1
            while j < len(text) and text[j] != '"':
                if text[j] == "\\":
                    j += 2
                else:
                    j += 1
            tokens.append(text[i : j + 1])
            i = j + 1
        # Handle parens
        elif text[i] in "()":
            tokens.append(text[i])
            i += 1
        # Handle other tokens
        else:
            j = i
            while j < len(text) and not text[j].isspace() and text[j] not in "()":
                j += 1
            tokens.append(text[i:j])
            i = j

    return tokens


def parse_sexpr(tokens: list[str], pos: int = 0) -> tuple[SExpr, int]:
    """Parse tokens into nested list structure."""
    if pos >= len(tokens):
        raise ValueError("Unexpected end of tokens")

    if tokens[pos] == "(":
        result: list[SExpr] = []
        pos += 1
        while pos < len(tokens) and tokens[pos] != ")":
            item, pos = parse_sexpr(tokens, pos)
            result.append(item)
        if pos >= len(tokens):
            raise ValueError("Unmatched opening parenthesis")
        return result, pos + 1
    elif tokens[pos] == ")":
        raise ValueError("Unexpected closing parenthesis")
    else:
        return tokens[pos], pos + 1


def sexpr_to_str(sexpr: SExpr) -> str:
    """Convert S-expression back to string."""
    if isinstance(sexpr, list):
        return "(" + " ".join(sexpr_to_str(item) for item in sexpr) + ")"
    return str(sexpr)


def extract_params_and_expr(fpcore_str: str) -> tuple[list[str], SExpr]:
    """Extract parameter names and the main expression from FPCore."""
    tokens = tokenize(fpcore_str)
    parsed, _ = parse_sexpr(tokens)

    if not isinstance(parsed, list) or len(parsed) < 3 or parsed[0] != "FPCore":
        raise ValueError("Invalid FPCore format")

    # Parameters are in the second position
    params = parsed[1]
    if not isinstance(params, list):
        raise ValueError("Parameters must be a list")

    # Extract string parameters
    param_names: list[str] = []
    for p in params:
        if isinstance(p, str):
            param_names.append(p)
        else:
            raise ValueError(f"Invalid parameter: {p}")

    # Expression is the last element
    expr = parsed[-1]

    return param_names, expr


def substitute_args(expr: SExpr, arg_map: dict[str, str]) -> SExpr:
    """Recursively substitute arg0, arg1, etc. with actual names."""
    if isinstance(expr, list):
        return [substitute_args(item, arg_map) for item in expr]
    elif expr in arg_map:
        return arg_map[expr]
    return expr


def add_alt_to_fpcore(
    original: str, alternative: str, filename: str | None = None
) -> str:
    """Add alternative expression to original FPCore with :alt field."""
    # Parse the original FPCore
    tokens = tokenize(original)
    parsed, _ = parse_sexpr(tokens)

    if not isinstance(parsed, list) or len(parsed) < 3 or parsed[0] != "FPCore":
        raise ValueError("Invalid FPCore format")

    # Extract parameters
    params = parsed[1]
    if not isinstance(params, list):
        raise ValueError("Parameters must be a list")

    param_names: list[str] = []
    for p in params:
        if isinstance(p, str):
            param_names.append(p)
        else:
            raise ValueError(f"Invalid parameter: {p}")

    # Parse the alternative and extract its expression
    _, alt_expr = extract_params_and_expr(alternative)

    # Create argument mapping
    arg_map = {f"arg{i}": param for i, param in enumerate(param_names)}

    # Substitute arguments in alternative expression
    substituted_expr = substitute_args(alt_expr, arg_map)

    # Build new FPCore structure: insert :alt before the final expression
    # Structure: [FPCore, params, properties..., expression]
    new_fpcore: list[SExpr] = ["FPCore", params]

    # Add all properties and the final expression, inserting :alt before the last element
    for i in range(2, len(parsed) - 1):
        new_fpcore.append(parsed[i])

    # Add the :alt property
    new_fpcore.append(":alt")
    if filename is not None:
        new_fpcore.append(["!", ":filename", f'"{filename}"', substituted_expr])
    else:
        new_fpcore.append(["!", substituted_expr])

    # Add the original expression
    new_fpcore.append(parsed[-1])

    # Convert back to string with formatting
    return format_fpcore(new_fpcore)


def format_fpcore(fpcore: list[SExpr]) -> str:
    """Format FPCore with proper indentation."""
    lines: list[str] = ["(FPCore"]

    for i, item in enumerate(fpcore[1:], 1):
        if i == 1:  # Parameters
            lines.append(" " + sexpr_to_str(item))
        elif isinstance(item, str) and item.startswith(":"):  # Property key
            lines.append(" " + item)
        else:  # Property value or expression
            lines.append(" " + sexpr_to_str(item))

    lines.append(")")
    return "\n".join(lines)


def main() -> None:
    """CLI entry point for adding alternative expressions to FPCore benchmarks."""
    parser = argparse.ArgumentParser(
        description="Add alternative expressions to FPCore benchmarks"
    )
    parser.add_argument("original", help="Path to the original FPCore benchmark file")
    parser.add_argument(
        "alternative", help="Path to the alternative FPCore expression file"
    )

    args = parser.parse_args()

    try:
        # Read input files
        with open(args.original) as f:
            original = f.read()

        with open(args.alternative) as f:
            alternative = f.read()

        # Process and output to stdout
        result = add_alt_to_fpcore(
            original, alternative, filename=Path(args.alternative).stem
        )
        sys.stdout.write(result)
        sys.stdout.write("\n")

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error parsing FPCore: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
