#ifndef HERBIE_MLIR_INTERVAL_SEARCH_H
#define HERBIE_MLIR_INTERVAL_SEARCH_H

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "rival.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mpfr.h>
#include <optional>
#include <random>
#include <utility>
#include <vector>

namespace herbie {

// ============================================================================
// Interval Representation
// ============================================================================

/// RAII wrapper for an MPFR interval [lo, hi].
/// Handles MPFR memory management automatically.
class Interval {
public:
  Interval(unsigned precision = 128);
  Interval(double lo, double hi, unsigned precision = 128);
  Interval(const mpfr_t loVal, const mpfr_t hiVal, unsigned precision = 128);
  ~Interval();

  // Copy semantics
  Interval(const Interval &other);
  Interval &operator=(const Interval &other);

  // Move semantics
  Interval(Interval &&other) noexcept;
  Interval &operator=(Interval &&other) noexcept;

  // Accessors
  const mpfr_t &lo() const { return lo_; }
  const mpfr_t &hi() const { return hi_; }
  mpfr_t &lo() { return lo_; }
  mpfr_t &hi() { return hi_; }

  unsigned precision() const { return precision_; }

  // Convenience getters
  double loAsDouble() const { return mpfr_get_d(lo_, MPFR_RNDN); }
  double hiAsDouble() const { return mpfr_get_d(hi_, MPFR_RNDN); }

  // Set from double values
  void setLo(double val) { mpfr_set_d(lo_, val, MPFR_RNDN); }
  void setHi(double val) { mpfr_set_d(hi_, val, MPFR_RNDN); }

private:
  mpfr_t lo_;
  mpfr_t hi_;
  unsigned precision_;
  bool initialized_ = false;

  void init();
  void clear();
};

// ============================================================================
// Hyperrectangle
// ============================================================================

/// A hyperrectangle is a vector of intervals, one per input variable.
using Hyperrect = std::vector<Interval>;

/// Create a hyperrect for the full domain of each float type.
Hyperrect createFullDomainRect(llvm::ArrayRef<unsigned> floatBitWidths,
                               unsigned precision = 128);

/// Create a hyperrect from explicit bounds.
Hyperrect createRect(llvm::ArrayRef<std::pair<double, double>> bounds,
                     unsigned precision = 128);

// ============================================================================
// Ordinal Space Utilities
// ============================================================================

/// Convert a 64-bit float to its ordinal representation.
/// Ordinal space treats the float bit pattern as an integer, with special
/// handling for negative numbers (flip bits for proper ordering).
uint64_t floatToOrdinal(double value);

/// Convert a 32-bit float to its ordinal representation.
uint32_t floatToOrdinal(float value);

/// Convert an ordinal back to a 64-bit float.
double ordinalToFloat64(uint64_t ordinal);

/// Convert an ordinal back to a 32-bit float.
float ordinalToFloat32(uint32_t ordinal);

/// Compute the weight (size in ordinal space) of a hyperrect.
/// Weight = product of (hi_ordinal - lo_ordinal + 1) for each dimension.
double hyperrectWeight(const Hyperrect &rect,
                       llvm::ArrayRef<unsigned> floatBitWidths);

/// Compute the total weight of the full domain for given types.
double totalWeight(llvm::ArrayRef<unsigned> floatBitWidths);

// ============================================================================
// Midpoint Finding
// ============================================================================

/// Result of finding midpoints for subdivision.
struct MidpointResult {
  double loMid; // The midpoint value
  double hiMid; // loMid rounded up to next float (creates gap)
};

/// Find midpoints for subdividing an interval.
/// Returns nullopt if the interval is too small to split (single float or
/// adjacent floats).
std::optional<MidpointResult> findMidpoints(const Interval &interval,
                                            unsigned floatBitWidth);

// ============================================================================
// Search Space
// ============================================================================

/// Custom deleter for RivalHints*.
struct RivalHintsDeleter {
  void operator()(RivalHints *hints) const {
    if (hints)
      rival_hints_free(hints);
  }
};

using RivalHintsPtr = std::unique_ptr<RivalHints, RivalHintsDeleter>;

/// A region with its associated hints.
struct RegionWithHints {
  Hyperrect rect;
  RivalHintsPtr hints;

  RegionWithHints() = default;
  RegionWithHints(Hyperrect r, RivalHints *h = nullptr)
      : rect(std::move(r)), hints(h) {}
  RegionWithHints(RegionWithHints &&) = default;
  RegionWithHints &operator=(RegionWithHints &&) = default;

  // No copy (unique_ptr)
  RegionWithHints(const RegionWithHints &) = delete;
  RegionWithHints &operator=(const RegionWithHints &) = delete;
};

/// The search space during subdivision.
struct SearchSpace {
  std::vector<RegionWithHints> trueRegions;  // Confirmed valid (evaluable)
  std::vector<RegionWithHints> falseRegions; // Confirmed invalid (always error)
  std::vector<RegionWithHints> otherRegions; // Undetermined (need subdivision)
};

// ============================================================================
// Sampling Statistics
// ============================================================================

struct SamplingTable {
  double validFraction;        // Fraction of space confirmed evaluable
  double invalidFraction;      // Fraction confirmed unevaluable
  double unknownFraction;      // Fraction still undetermined
  double preconditionFraction; // Fraction excluded by precondition (future use)

  SamplingTable()
      : validFraction(0), invalidFraction(0), unknownFraction(0),
        preconditionFraction(0) {}
};

// ============================================================================
// Search Result
// ============================================================================

struct SearchResult {
  std::vector<RegionWithHints> sampleableRegions; // true ∪ other
  SamplingTable statistics;
};

// ============================================================================
// Search Options
// ============================================================================

struct IntervalSearchOptions {
  unsigned maxSearchDepth = 128;     // Maximum subdivision iterations
  unsigned maxRegions = 1 << 17;     // Stop if region count exceeds this
  unsigned analysisPrecision = 128;  // MPFR precision for interval bounds
  unsigned maxRivalPrecision = 2000; // Max precision for Rival analysis
  unsigned maxRivalIterations = 5;   // Max Rival iterations per analysis
  bool emitStatistics = true;        // Whether to emit statistics
};

// ============================================================================
// Main Search Algorithm
// ============================================================================

/// Perform a single search step: classify regions and subdivide uncertain ones.
/// @param machine The compiled Rival machine for the expression.
/// @param space The current search space (modified in place).
/// @param splitDimension The dimension to split on this iteration.
/// @param floatBitWidths The bit widths of each input variable.
void searchStep(RivalMachine *machine, SearchSpace &space,
                unsigned splitDimension,
                llvm::ArrayRef<unsigned> floatBitWidths);

/// Find valid sampling regions for a Rival machine.
/// @param machine The compiled Rival machine for the expression.
/// @param initialRects Starting hyperrectangles (usually full domain).
/// @param floatBitWidths The bit widths of each input variable.
/// @param options Search configuration.
/// @return SearchResult containing sampleable regions and statistics.
SearchResult findIntervals(RivalMachine *machine,
                           llvm::ArrayRef<Hyperrect> initialRects,
                           llvm::ArrayRef<unsigned> floatBitWidths,
                           const IntervalSearchOptions &options);

/// Compute statistics for a search space.
SamplingTable computeStatistics(const SearchSpace &space,
                                llvm::ArrayRef<unsigned> floatBitWidths);

// ============================================================================
// Utility: Build arguments for Rival from a Hyperrect
// ============================================================================

/// Helper to build the mpfr_t pointer array that Rival expects.
class RivalRectArgs {
public:
  explicit RivalRectArgs(const Hyperrect &rect);
  ~RivalRectArgs();

  const mpfr_t *const *data() const { return ptrs_.data(); }
  size_t size() const { return ptrs_.size(); }

private:
  std::vector<const mpfr_t *> ptrs_;
};

// ============================================================================
// Function-Level Interval Search
// ============================================================================

/// Configuration object for storing rival and search options
struct IntervalSearchConfig {
  unsigned maxSearchDepth = 128;
  unsigned maxRegions = 131072;
  unsigned analysisPrecision = 128;
  unsigned maxRivalPrecision = 2000;
  unsigned maxRivalIterations = 5;
};

/// Result of running interval search on a function.
struct FunctionIntervalResult {
  SearchResult searchResult;
  std::vector<unsigned> floatBitWidths;
  bool success = false;
};

/// Run interval search on a function that implements RivalCompileableInterface.
/// Returns the search result containing sampleable regions and statistics.
FunctionIntervalResult
runIntervalSearchOnFunction(mlir::func::FuncOp funcOp,
                            const IntervalSearchConfig &config);

// ============================================================================
// Sampling
// ============================================================================

/// Result of sampling and evaluating points.
struct SamplingResult {
  std::vector<std::vector<double>> points;
  std::vector<std::vector<double>> results;
  unsigned sampled = 0;
  unsigned skipped = 0;
};

/// Build cumulative weight array from sampleable regions.
llvm::SmallVector<double>
buildCumulativeWeights(llvm::ArrayRef<RegionWithHints> regions,
                       llvm::ArrayRef<unsigned> floatBitWidths);

/// Sample a single random point from weighted sampleable regions.
/// Returns the sampled point and the index of the chosen region.
std::pair<std::vector<double>, size_t>
samplePoint(llvm::ArrayRef<RegionWithHints> regions,
            llvm::ArrayRef<double> cumulativeWeights,
            llvm::ArrayRef<unsigned> floatBitWidths, std::mt19937_64 &rng);

/// Sample numSamples points from the search result's sampleable regions,
/// evaluate them with per-root Rival machines, and return the results.
/// Each root expression gets its own RivalMachine so that a failure in one
/// root (e.g. division by zero) does not discard the entire sample point.
/// Failed roots receive NaN in the results.
SamplingResult sampleAndEvaluate(
    const RivalExprArena *arena, llvm::ArrayRef<uint32_t> roots,
    llvm::ArrayRef<const char *> varNames, const RivalDiscretization *disc,
    const SearchResult &searchResult, llvm::ArrayRef<unsigned> floatBitWidths,
    unsigned numSamples, unsigned evalMaxIterations, unsigned evalMaxPrecision,
    unsigned analysisPrecision, uint64_t seed = 42);

} // namespace herbie

#endif // HERBIE_MLIR_INTERVAL_SEARCH_H
