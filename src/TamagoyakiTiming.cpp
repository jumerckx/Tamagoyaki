#include "TamagoyakiTiming.h"

#include "mlir/Support/Timing.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/Signposts.h"
#include "llvm/Support/raw_ostream.h"

#include <memory>

using namespace mlir;

namespace {

struct TimingCLOptions {
  llvm::cl::opt<bool> enableTiming{
      "tamagoyaki-timing",
      llvm::cl::desc("Enable tamagoyaki timing instrumentation"),
      llvm::cl::init(false)};

  llvm::cl::opt<DefaultTimingManager::OutputFormat> outputFormat{
      "tamagoyaki-timing-output",
      llvm::cl::desc("Output format for tamagoyaki timing data"),
      llvm::cl::values(clEnumValN(DefaultTimingManager::OutputFormat::Text,
                                  "text", "display the results in text format"),
                       clEnumValN(DefaultTimingManager::OutputFormat::Json,
                                  "json",
                                  "display the results in JSON format")),
      llvm::cl::init(DefaultTimingManager::OutputFormat::Text)};
};

/// nanosecond resolution
class HighPrecisionJsonStrategy : public OutputStrategy {
public:
  HighPrecisionJsonStrategy(llvm::raw_ostream &os) : OutputStrategy(os) {}

  void printHeader(const TimeRecord &total) override { os << "[" << "\n"; }

  void printFooter() override {
    os << "]" << "\n";
    os.flush();
  }

  void printTime(const TimeRecord &time, const TimeRecord &total) override {
    if (total.user != total.wall) {
      os << "\"user\": {";
      os << "\"duration\": " << llvm::format("%.9f", time.user) << ", ";
      os << "\"percentage\": "
         << llvm::format("%5.1f", 100.0 * time.user / total.user);
      os << "}, ";
    }
    os << "\"wall\": {";
    os << "\"duration\": " << llvm::format("%.9f", time.wall) << ", ";
    os << "\"percentage\": "
       << llvm::format("%5.1f", 100.0 * time.wall / total.wall);
    os << "}";
  }

  void printListEntry(StringRef name, const TimeRecord &time,
                      const TimeRecord &total, bool lastEntry) override {
    os << "{";
    printTime(time, total);
    os << ", \"name\": " << "\"" << name << "\"";
    os << "}";
    if (!lastEntry)
      os << ",";
    os << "\n";
  }

  void printTreeEntry(unsigned indent, StringRef name, const TimeRecord &time,
                      const TimeRecord &total) override {
    os.indent(indent) << "{";
    printTime(time, total);
    os << ", \"name\": " << "\"" << name << "\"";
    os << ", \"passes\": [" << "\n";
  }

  void printTreeEntryEnd(unsigned indent, bool lastEntry) override {
    os.indent(indent) << "{}]";
    os << "}";
    if (!lastEntry)
      os << ",";
    os << "\n";
  }
};

llvm::ManagedStatic<TimingCLOptions> clOptions;

DefaultTimingManager *globalTM = nullptr;
TimingScope globalRootScope;
bool initialized = false;

/// Stack of active scopes so that getTimingScope nests under the innermost.
thread_local llvm::SmallVector<TimingScope *, 8> scopeStack;

/// Global signpost emitter for os_signpost instrumentation (Instruments.app).
llvm::ManagedStatic<llvm::SignpostEmitter> signposts;

/// Lazily initialize the timing manager. Safe to call multiple times.
void ensureInitialized() {
  if (initialized)
    return;
  initialized = true;
  if (!clOptions.isConstructed() || !clOptions->enableTiming)
    return;
  globalTM = new DefaultTimingManager();
  globalTM->setEnabled(true);
  if (clOptions->outputFormat == DefaultTimingManager::OutputFormat::Json)
    globalTM->setOutput(std::make_unique<HighPrecisionJsonStrategy>(llvm::errs()));
  else
    globalTM->setOutput(
        createOutputStrategy(clOptions->outputFormat, llvm::errs()));
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

tamagoyaki::SignpostGuard::SignpostGuard(llvm::StringRef name) : name(name) {
  signposts->startInterval(this, name);
}

tamagoyaki::SignpostGuard::~SignpostGuard() {
  signposts->endInterval(this, name);
}
