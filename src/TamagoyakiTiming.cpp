#include "TamagoyakiTiming.h"

#include "mlir/Support/Timing.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ManagedStatic.h"

using namespace mlir;

namespace {

struct TimingCLOptions {
  llvm::cl::opt<bool> enableTiming{
      "tamagoyaki-timing",
      llvm::cl::desc("Enable tamagoyaki timing instrumentation"),
      llvm::cl::init(false)};
};

llvm::ManagedStatic<TimingCLOptions> clOptions;

DefaultTimingManager *globalTM = nullptr;
TimingScope globalRootScope;
bool initialized = false;

/// Stack of active scopes so that getTimingScope nests under the innermost.
thread_local llvm::SmallVector<TimingScope *, 8> scopeStack;

/// Lazily initialize the timing manager. Safe to call multiple times.
void ensureInitialized() {
  if (initialized)
    return;
  initialized = true;
  if (!clOptions.isConstructed() || !clOptions->enableTiming)
    return;
  globalTM = new DefaultTimingManager();
  globalTM->setEnabled(true);
  globalRootScope = globalTM->getRootScope();
}

} // namespace

void tamagoyaki::registerTimingCLOptions() {
  // Force construction of the ManagedStatic to register the CL option.
  *clOptions;
}

void tamagoyaki::printTimingReport() {
  if (!globalTM)
    return;
  globalRootScope.stop();
  delete globalTM;
  globalTM = nullptr;
}

TimingScope &tamagoyaki::getRootTimingScope() {
  ensureInitialized();
  return globalRootScope;
}

TimingScope tamagoyaki::getTimingScope(llvm::StringRef name) {
  ensureInitialized();
  TimingScope *parent =
      scopeStack.empty() ? &globalRootScope : scopeStack.back();
  return parent->nest(name);
}

void tamagoyaki::pushTimingScope(mlir::TimingScope &scope) {
  scopeStack.push_back(&scope);
}

void tamagoyaki::popTimingScope() {
  if (!scopeStack.empty())
    scopeStack.pop_back();
}
