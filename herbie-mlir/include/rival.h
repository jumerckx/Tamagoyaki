#ifndef RIVAL_FFI_H
#define RIVAL_FFI_H

/* Generated with cbindgen:0.29.2 */

#include "mpfr.h"
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#define RIVAL_ABI_VERSION 1

#define RIVAL_EXPR_INVALID UINT32_MAX

enum RivalError
#ifdef __cplusplus
    : int32_t
#endif // __cplusplus
{
  RIVAL_ERROR_OK = 0,
  RIVAL_ERROR_INVALID_INPUT = -1,
  RIVAL_ERROR_UNSAMPLABLE = -2,
  RIVAL_ERROR_PANIC = -99,
};
#ifndef __cplusplus
typedef int32_t RivalError;
#endif // __cplusplus

enum RivalDiscType
#ifdef __cplusplus
    : uint32_t
#endif // __cplusplus
{
  RIVAL_DISC_TYPE_BOOL = 0,
  RIVAL_DISC_TYPE_F32 = 1,
  RIVAL_DISC_TYPE_F64 = 2,
};
#ifndef __cplusplus
typedef uint32_t RivalDiscType;
#endif // __cplusplus

enum RivalProfilingMode
#ifdef __cplusplus
    : uint32_t
#endif // __cplusplus
{
  RIVAL_PROFILING_MODE_OFF = 0,
  RIVAL_PROFILING_MODE_ON = 1,
};
#ifndef __cplusplus
typedef uint32_t RivalProfilingMode;
#endif // __cplusplus

typedef struct RivalDiscretization RivalDiscretization;

typedef struct RivalExprArena RivalExprArena;

typedef struct RivalHints RivalHints;

typedef struct RivalMachine RivalMachine;

typedef struct RivalAnalyzeResult {
  RivalError error;
  bool is_error;
  bool maybe_error;
  bool converged;
  struct RivalHints *hints;
} RivalAnalyzeResult;

typedef struct RivalExecution {
  int32_t instruction_idx;
  uint32_t precision;
  double time_ms;
  uint32_t iteration;
} RivalExecution;

typedef struct RivalAggregatedProfile {
  int32_t instruction_idx;
  uint32_t precision_bucket;
  double total_time_ms;
  uintptr_t count;
} RivalAggregatedProfile;

typedef struct RivalProfileSummary {
  const struct RivalAggregatedProfile *entries;
  uintptr_t len;
  uint32_t bumps;
  uint32_t iterations;
} RivalProfileSummary;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

uint32_t rival_version(void);

const char *rival_error_message(RivalError error);

struct RivalDiscretization *rival_disc_f64(uint32_t precision);

struct RivalDiscretization *rival_disc_f32(uint32_t precision);

struct RivalDiscretization *rival_disc_bool(void);

struct RivalDiscretization *rival_disc_mixed(const RivalDiscType *types,
                                             uintptr_t n_types,
                                             uint32_t precision);

void rival_disc_free(struct RivalDiscretization *disc);

struct RivalExprArena *rival_expr_arena_new(void);

struct RivalExprArena *rival_expr_arena_with_capacity(uintptr_t capacity);

void rival_expr_arena_free(struct RivalExprArena *arena);

uintptr_t rival_expr_arena_len(const struct RivalExprArena *arena);

void rival_expr_arena_clear(struct RivalExprArena *arena);

uint32_t rival_expr_var(struct RivalExprArena *arena, const char *name);

uint32_t rival_expr_f64(struct RivalExprArena *arena, double value);

uint32_t rival_expr_rational(struct RivalExprArena *arena, int64_t num,
                             int64_t den);

uint32_t rival_expr_pi(struct RivalExprArena *arena);

uint32_t rival_expr_e(struct RivalExprArena *arena);

uint32_t rival_expr_neg(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_fabs(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_sqrt(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_cbrt(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_pow2(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_exp(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_exp2(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_expm1(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_log(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_log2(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_log10(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_log1p(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_logb(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_sin(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_cos(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_tan(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_asin(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_acos(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_atan(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_sinh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_cosh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_tanh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_asinh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_acosh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_atanh(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_erf(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_erfc(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_rint(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_round(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_ceil(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_floor(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_trunc(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_not(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_assert(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_error(struct RivalExprArena *arena, uint32_t x);

uint32_t rival_expr_add(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_sub(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_mul(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_div(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_pow(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_hypot(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_fmin(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_fmax(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_fdim(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_copysign(struct RivalExprArena *arena, uint32_t x,
                             uint32_t y);

uint32_t rival_expr_fmod(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_remainder(struct RivalExprArena *arena, uint32_t x,
                              uint32_t y);

uint32_t rival_expr_atan2(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_and(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_or(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_eq(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_ne(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_lt(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_le(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_gt(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_ge(struct RivalExprArena *arena, uint32_t x, uint32_t y);

uint32_t rival_expr_fma(struct RivalExprArena *arena, uint32_t a, uint32_t b,
                        uint32_t c);

uint32_t rival_expr_if(struct RivalExprArena *arena, uint32_t a, uint32_t b,
                       uint32_t c);

uint32_t rival_expr_sinu(struct RivalExprArena *arena, uint64_t n, uint32_t x);

uint32_t rival_expr_cosu(struct RivalExprArena *arena, uint64_t n, uint32_t x);

uint32_t rival_expr_tanu(struct RivalExprArena *arena, uint64_t n, uint32_t x);

void rival_hints_free(struct RivalHints *hints);

uintptr_t rival_hints_len(const struct RivalHints *hints);

struct RivalMachine *
rival_machine_new(const struct RivalExprArena *arena,
                  const uint32_t *expr_handles, uintptr_t n_exprs,
                  const char *const *vars, uintptr_t n_vars,
                  const struct RivalDiscretization *disc,
                  uint32_t max_precision, uintptr_t profile_capacity);

void rival_machine_free(struct RivalMachine *machine);

uintptr_t rival_machine_instruction_count(const struct RivalMachine *machine);

uintptr_t rival_machine_var_count(const struct RivalMachine *machine);

uintptr_t rival_machine_expr_count(const struct RivalMachine *machine);

RivalError rival_apply(struct RivalMachine *machine, const mpfr_t *const *args,
                       uintptr_t n_args, mpfr_t *const *out, uintptr_t n_out,
                       const struct RivalHints *hints, uintptr_t max_iterations,
                       uint32_t max_precision);

struct RivalAnalyzeResult
rival_analyze_with_hints(struct RivalMachine *machine,
                         const mpfr_t *const *rect, uintptr_t n_args,
                         const struct RivalHints *hints);

RivalError rival_analyze(struct RivalMachine *machine,
                         const mpfr_t *const *rect, uintptr_t n_args,
                         bool *is_error, bool *maybe_error);

uintptr_t rival_profiler_count(const struct RivalMachine *machine);

bool rival_profiler_get(const struct RivalMachine *machine, uintptr_t idx,
                        struct RivalExecution *out);

void rival_profiler_reset(struct RivalMachine *machine);

struct RivalProfileSummary
rival_profiler_aggregate(struct RivalMachine *machine, uint32_t bucket_size);

const struct RivalExecution *
rival_profiler_executions(struct RivalMachine *machine, uintptr_t *out_len);

const uint8_t *rival_instruction_names(struct RivalMachine *machine,
                                       uintptr_t *out_len);

uint32_t rival_machine_iterations(const struct RivalMachine *machine);

uint32_t rival_machine_bumps(const struct RivalMachine *machine);

void rival_machine_set_profiling(struct RivalMachine *machine,
                                 RivalProfilingMode mode);

RivalProfilingMode
rival_machine_get_profiling(const struct RivalMachine *machine);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif /* RIVAL_FFI_H */
