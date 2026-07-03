//===- EquivalenceSelectIlp.cpp - ILP-based e-node selection ----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Driver for the `equivalence-select-ilp` pass, which selects one e-node per
// e-class by solving an integer linear program. The ILP is solved with HiGHS
// (https://highs.dev).
//
// This file is compiled unconditionally so that the pass is always registered.
// The HiGHS-backed body, however, is only available when the project is
// configured with `-DTAMAGOYAKI_ENABLE_HIGHS=ON` (the default). Without HiGHS
// the pass still registers but fails at run time with a diagnostic, so builds
// that disable the dependency stay linkable and the pass is simply unavailable.
//
// The full extraction model is not implemented yet: the HiGHS branch currently
// just solves a trivial ILP to prove the integration links and runs.
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Support/LLVM.h"
#include "llvm/Support/raw_ostream.h"

#ifdef TAMAGOYAKI_HIGHS_ENABLED
#include "Highs.h"
#endif

using namespace mlir;
using namespace mlir::equivalence;

namespace mlir::equivalence {
#define GEN_PASS_DEF_EQUIVALENCESELECTILP
#include "EquivalencePasses.h.inc"

namespace {

class EquivalenceSelectIlp
    : public impl::EquivalenceSelectIlpBase<EquivalenceSelectIlp> {
public:
  using impl::EquivalenceSelectIlpBase<
      EquivalenceSelectIlp>::EquivalenceSelectIlpBase;

  void runOnOperation() final {
#ifndef TAMAGOYAKI_HIGHS_ENABLED
    getOperation().emitError()
        << "equivalence-select-ilp is unavailable: tamagoyaki was built "
           "without HiGHS support (reconfigure with "
           "-DTAMAGOYAKI_ENABLE_HIGHS=ON)";
    return signalPassFailure();
#else
    // Placeholder ILP; the real extraction model is not implemented yet. Solve
    // a trivial integer program to exercise the HiGHS integration end to end:
    //   minimize  x + y   s.t.   1 <= x + y <= 2,   x, y in {0, 1}
    HighsModel model;
    model.lp_.num_col_ = 2;
    model.lp_.num_row_ = 1;
    model.lp_.sense_ = ObjSense::kMinimize;
    model.lp_.offset_ = 0.0;
    model.lp_.col_cost_ = {1.0, 1.0};
    model.lp_.col_lower_ = {0.0, 0.0};
    model.lp_.col_upper_ = {1.0, 1.0};
    model.lp_.row_lower_ = {1.0};
    model.lp_.row_upper_ = {2.0};
    model.lp_.a_matrix_.format_ = MatrixFormat::kColwise;
    model.lp_.a_matrix_.start_ = {0, 1, 2};
    model.lp_.a_matrix_.index_ = {0, 0};
    model.lp_.a_matrix_.value_ = {1.0, 1.0};
    model.lp_.integrality_ = {HighsVarType::kInteger, HighsVarType::kInteger};

    Highs highs;
    highs.setOptionValue("output_flag", false);
    if (highs.passModel(model) != HighsStatus::kOk ||
        highs.run() != HighsStatus::kOk) {
      getOperation().emitError("HiGHS failed to solve the ILP");
      return signalPassFailure();
    }

    llvm::outs() << "HiGHS " << HIGHS_VERSION_MAJOR << "."
                 << HIGHS_VERSION_MINOR << "." << HIGHS_VERSION_PATCH
                 << " solved ILP: objective = "
                 << highs.getInfo().objective_function_value << "\n";
#endif
  }
};

} // namespace
} // namespace mlir::equivalence
