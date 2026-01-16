#ifndef HERBIE_MLIR_INTERVAL_ANALYSIS_H
#define HERBIE_MLIR_INTERVAL_ANALYSIS_H

#include "RivalCAPI.h"
#include "mlir/Analysis/DataFlow/SparseAnalysis.h"
#include "mlir/IR/Value.h"
#include "llvm/Support/raw_ostream.h"
#include <memory>

namespace herbie {

struct IvalSharedDeleter {
  void operator()(rival_Ival *p) const {
    if (p)
      rival_ival_free(p);
  }
};

using IvalSharedPtr = std::shared_ptr<rival_Ival>;

inline IvalSharedPtr makeSharedIval(rival_Ival *raw) {
  return IvalSharedPtr(raw, IvalSharedDeleter());
}

class IntervalValue {
public:
  IntervalValue() : initialized(false), interval(nullptr) {}

  explicit IntervalValue(IvalSharedPtr ival)
      : initialized(true), interval(std::move(ival)) {}

  static IntervalValue getUnknown() {
    IntervalValue v;
    v.initialized = true;
    v.interval = nullptr;
    return v;
  }

  bool isUninitialized() const { return !initialized; }

  bool isUnknown() const { return initialized && interval == nullptr; }

  const rival_Ival *getInterval() const { return interval.get(); }

  static IntervalValue join(const IntervalValue &lhs, const IntervalValue &rhs);

  bool operator==(const IntervalValue &rhs) const;

  void print(llvm::raw_ostream &os) const;

private:
  bool initialized;
  IvalSharedPtr interval;
};

inline llvm::raw_ostream &operator<<(llvm::raw_ostream &os,
                                     const IntervalValue &v) {
  v.print(os);
  return os;
}

using IntervalLattice = mlir::dataflow::Lattice<IntervalValue>;

class IntervalAnalysis
    : public mlir::dataflow::SparseForwardDataFlowAnalysis<IntervalLattice> {
public:
  using SparseForwardDataFlowAnalysis::SparseForwardDataFlowAnalysis;

  mlir::LogicalResult
  visitOperation(mlir::Operation *op,
                 llvm::ArrayRef<const IntervalLattice *> operands,
                 llvm::ArrayRef<IntervalLattice *> results) override;

  void setToEntryState(IntervalLattice *lattice) override;
};

} // namespace herbie

#endif // HERBIE_MLIR_INTERVAL_ANALYSIS_H
