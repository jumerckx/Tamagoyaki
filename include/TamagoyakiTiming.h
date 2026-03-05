#ifndef TAMAGOYAKI_TIMING_H
#define TAMAGOYAKI_TIMING_H

#include "mlir/Support/Timing.h"
#include "llvm/ADT/StringRef.h"

namespace tamagoyaki {

/// Register the --tamagoyaki-timing CLI option. Call once at program startup
/// before llvm::cl::ParseCommandLineOptions (i.e., before MlirOptMain).
void registerTimingCLOptions();

/// Print and reset the global timing report. Call before program exit.
void printTimingReport();

/// Return the global root TimingScope. Returns an empty (no-op) scope if
/// timing is disabled. The timing manager is lazily initialized on first use.
mlir::TimingScope &getRootTimingScope();

/// Return a nested TimingScope under the current innermost active scope
/// (or the global root if none is active). The scope automatically starts
/// timing on construction and stops on destruction (RAII).
mlir::TimingScope getTimingScope(llvm::StringRef name);

/// Push a scope onto the thread-local stack so that subsequent
/// getTimingScope calls nest under it.
void pushTimingScope(mlir::TimingScope &scope);

/// Pop the innermost scope from the thread-local stack.
void popTimingScope();

/// RAII guard that pushes a scope on construction and pops it on destruction.
struct TimingScopeGuard {
  explicit TimingScopeGuard(mlir::TimingScope &scope) {
    pushTimingScope(scope);
  }
  ~TimingScopeGuard() { popTimingScope(); }
  TimingScopeGuard(const TimingScopeGuard &) = delete;
  TimingScopeGuard &operator=(const TimingScopeGuard &) = delete;
};

} // namespace tamagoyaki

/// Convenience macro: create a TimingScope for the current block and push it
/// so that any nested TAMAGOYAKI_SCOPED_TIMER calls become children.
#define TAMAGOYAKI_CONCAT_(a, b) a##b
#define TAMAGOYAKI_CONCAT(a, b) TAMAGOYAKI_CONCAT_(a, b)
#define TAMAGOYAKI_SCOPED_TIMER(name)                                          \
  auto TAMAGOYAKI_CONCAT(_tamagoyakiTS, __LINE__) =                            \
      tamagoyaki::getTimingScope(name);                                        \
  tamagoyaki::TimingScopeGuard TAMAGOYAKI_CONCAT(_tamagoyakiTG, __LINE__)(     \
      TAMAGOYAKI_CONCAT(_tamagoyakiTS, __LINE__))

#endif // TAMAGOYAKI_TIMING_H
