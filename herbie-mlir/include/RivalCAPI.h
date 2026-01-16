/**
 * Rival C API - High-precision interval arithmetic library
 *
 * This header provides C-compatible bindings to the Rival library
 * for evaluating floating-point expressions with adaptive precision tuning.
 */

#ifndef RIVAL_H
#define RIVAL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * Error codes
 * ========================================================================== */

typedef enum {
  RIVAL_OK = 0,
  RIVAL_INVALID_INPUT = 1,
  RIVAL_UNSAMPLABLE = 2,
  RIVAL_MEMORY_ERROR = 3,
  RIVAL_INVALID_ARGUMENT = 4,
} rival_error_t;

/* ============================================================================
 * Basic types
 * ========================================================================== */

typedef double rival_f64;
typedef bool rival_bool;

/* Opaque pointers for complex types */
typedef struct rival_Float rival_Float;
typedef struct rival_Rational rival_Rational;
typedef struct rival_Ival rival_Ival;
typedef struct rival_Expr rival_Expr;
typedef struct rival_Machine rival_Machine;
typedef struct rival_MachineBuilder rival_MachineBuilder;

/* ============================================================================
 * Discretization callback interface
 * ========================================================================== */

typedef struct {
  uint32_t (*target)(void *userdata);
  rival_Float *(*convert)(void *userdata, size_t idx, const rival_Float *v);
  size_t (*distance)(void *userdata, size_t idx, const rival_Float *lo,
                     const rival_Float *hi);
  void (*destroy)(void *userdata);
} rival_Discretization;

/* ============================================================================
 * Hint types
 * ========================================================================== */

typedef enum {
  RIVAL_HINT_EXECUTE = 0,
  RIVAL_HINT_SKIP = 1,
  RIVAL_HINT_ALIAS = 2,
  RIVAL_HINT_KNOWN_BOOL = 3,
} rival_hint_kind_t;

typedef union {
  uint8_t input_index;
  bool bool_value;
} rival_hint_data;

typedef struct {
  rival_hint_kind_t kind;
  rival_hint_data data;
} rival_Hint;

/* ============================================================================
 * Profiling
 * ========================================================================== */

typedef struct {
  const char *name;
  int32_t number;
  uint32_t precision;
  double time_ms;
  size_t iteration;
} rival_Execution;

/* ============================================================================
 * Float operations
 * ========================================================================== */

rival_Float *rival_float_new(uint32_t precision);
rival_Float *rival_float_from_f64(uint32_t precision, rival_f64 value);
rival_Float *rival_float_from_str(uint32_t precision, const char *str);
uint32_t rival_float_precision(const rival_Float *f);
void rival_float_set_precision(rival_Float *f, uint32_t precision);
rival_f64 rival_float_to_f64(const rival_Float *f);
char *rival_float_to_string(const rival_Float *f, int radix);
rival_Float *rival_float_clone(const rival_Float *f);
int rival_float_cmp(const rival_Float *a, const rival_Float *b);
rival_bool rival_float_is_zero(const rival_Float *f);
rival_bool rival_float_is_infinite(const rival_Float *f);
rival_bool rival_float_is_nan(const rival_Float *f);
void rival_float_free(rival_Float *f);
void rival_string_free(char *s);

/* ============================================================================
 * Rational operations
 * ========================================================================== */

rival_Rational *rival_rational_new(int64_t numerator, int64_t denominator);
rival_Rational *rival_rational_from_str(const char *str);
rival_Float *rival_rational_to_float(const rival_Rational *r,
                                     uint32_t precision);
int64_t rival_rational_numerator(const rival_Rational *r);
int64_t rival_rational_denominator(const rival_Rational *r);
rival_Rational *rival_rational_clone(const rival_Rational *r);
void rival_rational_free(rival_Rational *r);

/* ============================================================================
 * Interval operations
 * ========================================================================== */

rival_Ival *rival_ival_new(const rival_Float *lo, const rival_Float *hi);
rival_Ival *rival_ival_from_f64(uint32_t precision, rival_f64 value);
rival_Ival *rival_ival_bool(rival_bool lo_true, rival_bool hi_true);
rival_Ival *rival_ival_zero(uint32_t precision);
const rival_Float *rival_ival_lower(const rival_Ival *iv);
const rival_Float *rival_ival_upper(const rival_Ival *iv);
uint32_t rival_ival_precision(const rival_Ival *iv);
rival_bool rival_ival_has_partial_error(const rival_Ival *iv);
rival_bool rival_ival_has_total_error(const rival_Ival *iv);
int rival_ival_known_bool(const rival_Ival *iv);
rival_Ival *rival_ival_clone(const rival_Ival *iv);
void rival_ival_free(rival_Ival *iv);
void rival_ival_array_free(rival_Ival **array, size_t count);

/* ============================================================================
 * Expression operations
 * ========================================================================== */

/* Variable and literals */
rival_Expr *rival_expr_var(const char *name);
rival_Expr *rival_expr_literal(const rival_Float *val);
rival_Expr *rival_expr_pi(void);
rival_Expr *rival_expr_e(void);

/* Unary operations */
rival_Expr *rival_expr_neg(rival_Expr *arg);
rival_Expr *rival_expr_fabs(rival_Expr *arg);
rival_Expr *rival_expr_sqrt(rival_Expr *arg);
rival_Expr *rival_expr_cbrt(rival_Expr *arg);
rival_Expr *rival_expr_exp(rival_Expr *arg);
rival_Expr *rival_expr_exp2(rival_Expr *arg);
rival_Expr *rival_expr_expm1(rival_Expr *arg);
rival_Expr *rival_expr_log(rival_Expr *arg);
rival_Expr *rival_expr_log2(rival_Expr *arg);
rival_Expr *rival_expr_log10(rival_Expr *arg);
rival_Expr *rival_expr_log1p(rival_Expr *arg);
rival_Expr *rival_expr_sin(rival_Expr *arg);
rival_Expr *rival_expr_cos(rival_Expr *arg);
rival_Expr *rival_expr_tan(rival_Expr *arg);
rival_Expr *rival_expr_asin(rival_Expr *arg);
rival_Expr *rival_expr_acos(rival_Expr *arg);
rival_Expr *rival_expr_atan(rival_Expr *arg);
rival_Expr *rival_expr_sinh(rival_Expr *arg);
rival_Expr *rival_expr_cosh(rival_Expr *arg);
rival_Expr *rival_expr_tanh(rival_Expr *arg);
rival_Expr *rival_expr_asinh(rival_Expr *arg);
rival_Expr *rival_expr_acosh(rival_Expr *arg);
rival_Expr *rival_expr_atanh(rival_Expr *arg);
rival_Expr *rival_expr_erf(rival_Expr *arg);
rival_Expr *rival_expr_erfc(rival_Expr *arg);
rival_Expr *rival_expr_floor(rival_Expr *arg);
rival_Expr *rival_expr_ceil(rival_Expr *arg);
rival_Expr *rival_expr_round(rival_Expr *arg);
rival_Expr *rival_expr_trunc(rival_Expr *arg);
rival_Expr *rival_expr_rint(rival_Expr *arg);
rival_Expr *rival_expr_logb(rival_Expr *arg);
rival_Expr *rival_expr_pow2(rival_Expr *arg);
rival_Expr *rival_expr_not(rival_Expr *arg);

/* Binary operations */
rival_Expr *rival_expr_add(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_sub(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_mul(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_div(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_pow(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_hypot(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_atan2(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_fmin(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_fmax(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_fmod(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_remainder(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_copysign(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_fdim(rival_Expr *left, rival_Expr *right);

/* Comparison operations */
rival_Expr *rival_expr_eq(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_ne(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_lt(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_le(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_gt(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_ge(rival_Expr *left, rival_Expr *right);

/* Boolean operations */
rival_Expr *rival_expr_and(rival_Expr *left, rival_Expr *right);
rival_Expr *rival_expr_or(rival_Expr *left, rival_Expr *right);

/* Ternary operations */
rival_Expr *rival_expr_if(rival_Expr *cond, rival_Expr *then_expr,
                          rival_Expr *else_expr);

/* Expression utilities */
rival_Expr *rival_expr_clone(const rival_Expr *expr);
void rival_expr_free(rival_Expr *expr);

/* ============================================================================
 * Machine operations
 * ========================================================================== */

rival_MachineBuilder *rival_machine_builder_new(rival_Discretization disc,
                                                void *userdata);
rival_MachineBuilder *
rival_machine_builder_min_precision(rival_MachineBuilder *builder,
                                    uint32_t precision);
rival_MachineBuilder *
rival_machine_builder_max_precision(rival_MachineBuilder *builder,
                                    uint32_t precision);
rival_MachineBuilder *
rival_machine_builder_enable_profiling(rival_MachineBuilder *builder,
                                       rival_bool enabled);

rival_error_t rival_machine_builder_build(rival_MachineBuilder *builder,
                                          rival_Expr **exprs, size_t num_exprs,
                                          const char **vars, size_t num_vars,
                                          rival_Machine **out_machine);

void rival_machine_builder_free(rival_MachineBuilder *builder);
void rival_machine_free(rival_Machine *machine);

size_t rival_machine_num_instructions(const rival_Machine *machine);

/* ============================================================================
 * Evaluation
 * ========================================================================== */

rival_error_t rival_machine_apply(rival_Machine *machine,
                                  const rival_Ival **inputs, size_t num_inputs,
                                  rival_Ival ***out_results, size_t *out_count,
                                  size_t max_iterations);

rival_error_t rival_machine_iterate(rival_Machine *machine,
                                    const rival_Ival **inputs,
                                    size_t num_inputs, const rival_Hint *hints,
                                    size_t num_hints, rival_Ival ***out_results,
                                    size_t *out_count, size_t iteration_number);

rival_error_t rival_machine_analyze(rival_Machine *machine,
                                    const rival_Ival **inputs,
                                    size_t num_inputs, rival_Ival **out_status,
                                    rival_Hint **out_hints,
                                    size_t *out_hint_count,
                                    rival_bool *out_converged);

/* ============================================================================
 * Profiling
 * ========================================================================== */

const rival_Execution *
rival_machine_profiling_data(const rival_Machine *machine, size_t *out_count);
rival_error_t rival_machine_take_profiling(rival_Machine *machine,
                                           rival_Execution **out_results,
                                           size_t *out_count);

void rival_hint_array_free(rival_Hint *hints);
void rival_execution_array_free(rival_Execution *array);

/* ============================================================================
 * Utilities
 * ========================================================================== */

const char *rival_version(void);
const char *rival_error_string(rival_error_t err);

#ifdef __cplusplus
}
#endif

#endif /* RIVAL_H */
