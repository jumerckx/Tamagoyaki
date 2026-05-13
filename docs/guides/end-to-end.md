# A Simple End-to-End Example

This guide goes over the hello world example of e-graphs: optimizing `(a * 2) / 2`.
This expression can be translated to MLIR IR:
```mlir
# input.mlir
func.func @example(%a: i32) -> (i32, i32) {
  %two = arith.constant 2 : i32
  %mul = arith.muli %a, %two : i32
  %div = arith.divi %mul, %two : i32
  return %div : i32, i32
}
```
Assuming you have succesfully built Tamagoyaki, we can convert this function body into an e-graph:
```
tamagoyaki-opt --equivalence-insert-graph input.mlir
```
```
func.func @example(%a: i32) -> (i32, i32) {

  %two = arith.constant 2 : i32
  %mul = arith.muli %a, %two : i32
  %div = arith.divi %mul, %two : i32
  return %div : i32, i32
}
```
