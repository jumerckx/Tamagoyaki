# Vendored standard-cell library

`asap7.genlib` is the ASAP7 cell library in ABC `genlib` format, used by the
Rover evaluation to technology-map the AIGER netlists that come out of
`circt-synth` (`abc -c "read_genlib asap7.genlib; read x.aig; strash; map;
print_stats"`).

It is vendored rather than fetched at run time so that `nix run .#rover-eval`
works offline and every reported area/delay number is tied to a file in the
checkout. The Snakefile records its sha256 in the provenance manifest; override
it with `EXTRA_CONFIG='genlib=/path/to/other.genlib' rover-eval`.

## Provenance

| | |
|---|---|
| Upstream | <https://github.com/cowardsa/DatapathBench/tree/main/libraries> |
| Commit | `fe5941cf234bd543c45e8ccea5c10f8c95232b6f` |
| Upstream license | MIT |
| `asap7.genlib` sha256 | `a49947a67b2d2a2432e16aa4a697a18cec5fbd90adf71243f3dc44ae8288d7fb` |
| `NOTICE.md` sha256 | `dcf564b3856aafdbe82f02417bf1a06f7fbd4c6b2df599027244f10f4b755886` |

`NOTICE.md` is upstream's, kept verbatim: the file derives from
[mockturtle](https://github.com/lsils/mockturtle) (MIT) and the ASAP7 7nm
predictive PDK (BSD 3-Clause, Arizona State University with ARM Research).

Work published using these numbers must cite:

> L. T. Clark et al., "ASAP7: A 7-nm FinFET Predictive Process Design Kit,"
> *Microelectronics Journal*, vol. 53, pp. 105-115, July 2016.

## Refreshing

```shell
base=https://raw.githubusercontent.com/cowardsa/DatapathBench/<commit>/libraries
curl -fsSL -o asap7.genlib "$base/asap7.genlib"
curl -fsSL -o NOTICE.md    "$base/NOTICE.md"
```

Update the commit and both hashes in the table above when you do.
