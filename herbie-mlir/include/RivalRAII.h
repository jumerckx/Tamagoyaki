/**
 * Rival RAII Wrappers - C++ memory-safe wrappers for Rival C API
 *
 * Provides std::unique_ptr aliases with custom deleters for automatic
 * resource cleanup of Rival types.
 */

#ifndef RIVAL_RAII_H
#define RIVAL_RAII_H

#include "RivalCAPI.h"
#include <memory>
#include <string>

namespace rival {

// Custom deleters for Rival types
struct FloatDeleter {
  void operator()(rival_Float *p) const {
    if (p)
      rival_float_free(p);
  }
};

struct RationalDeleter {
  void operator()(rival_Rational *p) const {
    if (p)
      rival_rational_free(p);
  }
};

struct IvalDeleter {
  void operator()(rival_Ival *p) const {
    if (p)
      rival_ival_free(p);
  }
};

struct ExprDeleter {
  void operator()(rival_Expr *p) const {
    if (p)
      rival_expr_free(p);
  }
};

struct MachineDeleter {
  void operator()(rival_Machine *p) const {
    if (p)
      rival_machine_free(p);
  }
};

struct MachineBuilderDeleter {
  void operator()(rival_MachineBuilder *p) const {
    if (p)
      rival_machine_builder_free(p);
  }
};

struct StringDeleter {
  void operator()(char *p) const {
    if (p)
      rival_string_free(p);
  }
};

struct HintArrayDeleter {
  void operator()(rival_Hint *p) const {
    if (p)
      rival_hint_array_free(p);
  }
};

struct ExecutionArrayDeleter {
  void operator()(rival_Execution *p) const {
    if (p)
      rival_execution_array_free(p);
  }
};

// Smart pointer type aliases
using FloatPtr = std::unique_ptr<rival_Float, FloatDeleter>;
using RationalPtr = std::unique_ptr<rival_Rational, RationalDeleter>;
using IvalPtr = std::unique_ptr<rival_Ival, IvalDeleter>;
using ExprPtr = std::unique_ptr<rival_Expr, ExprDeleter>;
using MachinePtr = std::unique_ptr<rival_Machine, MachineDeleter>;
using MachineBuilderPtr =
    std::unique_ptr<rival_MachineBuilder, MachineBuilderDeleter>;
using StringPtr = std::unique_ptr<char, StringDeleter>;
using HintArrayPtr = std::unique_ptr<rival_Hint, HintArrayDeleter>;
using ExecutionArrayPtr =
    std::unique_ptr<rival_Execution, ExecutionArrayDeleter>;

// Factory functions for convenient construction
inline FloatPtr makeFloat(uint32_t precision) {
  return FloatPtr(rival_float_new(precision));
}

inline FloatPtr makeFloat(uint32_t precision, double value) {
  return FloatPtr(rival_float_from_f64(precision, value));
}

inline FloatPtr makeFloat(uint32_t precision, const char *str) {
  return FloatPtr(rival_float_from_str(precision, str));
}

inline RationalPtr makeRational(int64_t numerator, int64_t denominator) {
  return RationalPtr(rival_rational_new(numerator, denominator));
}

inline RationalPtr makeRational(const char *str) {
  return RationalPtr(rival_rational_from_str(str));
}

inline IvalPtr makeIval(const rival_Float *lo, const rival_Float *hi) {
  return IvalPtr(rival_ival_new(lo, hi));
}

inline IvalPtr makeIval(uint32_t precision, double value) {
  return IvalPtr(rival_ival_from_f64(precision, value));
}

inline IvalPtr makeIvalBool(bool lo_true, bool hi_true) {
  return IvalPtr(rival_ival_bool(lo_true, hi_true));
}

inline IvalPtr makeIvalZero(uint32_t precision) {
  return IvalPtr(rival_ival_zero(precision));
}

// Expression factories
inline ExprPtr exprVar(const char *name) {
  return ExprPtr(rival_expr_var(name));
}

inline ExprPtr exprLiteral(const rival_Float *val) {
  return ExprPtr(rival_expr_literal(val));
}

inline ExprPtr exprPi() { return ExprPtr(rival_expr_pi()); }

inline ExprPtr exprE() { return ExprPtr(rival_expr_e()); }

// Helper to convert rival string to std::string
inline std::string toString(const rival_Float *f, int radix = 10) {
  StringPtr s(rival_float_to_string(f, radix));
  return s ? std::string(s.get()) : std::string();
}

} // namespace rival

#endif /* RIVAL_RAII_H */
