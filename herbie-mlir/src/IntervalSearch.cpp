#include "IntervalSearch.h"
#include "HerbieMLIROpInterfaces.h"
#include "TamagoyakiTiming.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinTypeInterfaces.h"
#include "mlir/IR/Types.h"
#include "mlir/Support/LLVM.h"
#include "rival.h"
#include "llvm/ADT/ArrayRef.h"
#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <optional>
#include <random>
#include <string>
#include <utility>
#include <vector>

using namespace herbie;

// ============================================================================
// Interval Implementation
// ============================================================================

Interval::Interval(unsigned precision) : precision_(precision) { init(); }

Interval::Interval(double lo, double hi, unsigned precision)
    : precision_(precision) {
  init();
  mpfr_set_d(lo_, lo, MPFR_RNDN);
  mpfr_set_d(hi_, hi, MPFR_RNDN);
}

Interval::Interval(const mpfr_t loVal, const mpfr_t hiVal, unsigned precision)
    : precision_(precision) {
  init();
  mpfr_set(lo_, loVal, MPFR_RNDN);
  mpfr_set(hi_, hiVal, MPFR_RNDN);
}

Interval::~Interval() { clear(); }

Interval::Interval(const Interval &other) : precision_(other.precision_) {
  init();
  mpfr_set(lo_, other.lo_, MPFR_RNDN);
  mpfr_set(hi_, other.hi_, MPFR_RNDN);
}

Interval &Interval::operator=(const Interval &other) {
  if (this != &other) {
    if (initialized_ && precision_ != other.precision_) {
      clear();
      precision_ = other.precision_;
      init();
    }
    mpfr_set(lo_, other.lo_, MPFR_RNDN);
    mpfr_set(hi_, other.hi_, MPFR_RNDN);
  }
  return *this;
}

Interval::Interval(Interval &&other) noexcept
    : precision_(other.precision_), initialized_(other.initialized_) {
  if (other.initialized_) {
    std::memcpy(&lo_, &other.lo_, sizeof(mpfr_t));
    std::memcpy(&hi_, &other.hi_, sizeof(mpfr_t));
    other.initialized_ = false;
  }
}

Interval &Interval::operator=(Interval &&other) noexcept {
  if (this != &other) {
    clear();
    precision_ = other.precision_;
    initialized_ = other.initialized_;
    if (other.initialized_) {
      std::memcpy(&lo_, &other.lo_, sizeof(mpfr_t));
      std::memcpy(&hi_, &other.hi_, sizeof(mpfr_t));
      other.initialized_ = false;
    }
  }
  return *this;
}

void Interval::init() {
  mpfr_init2(lo_, precision_);
  mpfr_init2(hi_, precision_);
  initialized_ = true;
}

void Interval::clear() {
  if (initialized_) {
    mpfr_clear(lo_);
    mpfr_clear(hi_);
    initialized_ = false;
  }
}

// ============================================================================
// Ordinal Space Utilities
// ============================================================================

namespace {

/// The total number of ordinals for a given float bit width.
inline double totalOrdinals(unsigned bitWidth) {
  if (bitWidth == 32)
    return 4294967296.0; // 2^32
  if (bitWidth == 64)
    return 18446744073709551616.0; // 2^64
  return std::pow(2.0, bitWidth);
}

} // namespace

uint64_t herbie::floatToOrdinal(double value) {
  uint64_t bits;
  std::memcpy(&bits, &value, sizeof(double));

  // Handle NaN and Inf specially - map to extremes
  if (std::isnan(value))
    return UINT64_MAX;
  if (std::isinf(value))
    return value > 0 ? (UINT64_MAX - 1) : 0;

  // For negative numbers, flip all bits to maintain ordering
  // For positive numbers, flip just the sign bit
  if (bits & (uint64_t(1) << 63)) {
    // Negative: flip all bits
    return ~bits;
  } else {
    // Positive: flip sign bit to put after negatives
    return bits ^ (uint64_t(1) << 63);
  }
}

uint32_t herbie::floatToOrdinal(float value) {
  uint32_t bits;
  std::memcpy(&bits, &value, sizeof(float));

  if (std::isnan(value))
    return UINT32_MAX;
  if (std::isinf(value))
    return value > 0 ? (UINT32_MAX - 1) : 0;

  if (bits & (uint32_t(1) << 31)) {
    return ~bits;
  } else {
    return bits ^ (uint32_t(1) << 31);
  }
}

double herbie::ordinalToFloat64(uint64_t ordinal) {
  // Reverse the transformation
  uint64_t bits;
  if (ordinal & (uint64_t(1) << 63)) {
    // Was positive: flip sign bit back
    bits = ordinal ^ (uint64_t(1) << 63);
  } else {
    // Was negative: flip all bits back
    bits = ~ordinal;
  }

  double result;
  std::memcpy(&result, &bits, sizeof(double));
  return result;
}

float herbie::ordinalToFloat32(uint32_t ordinal) {
  uint32_t bits;
  if (ordinal & (uint32_t(1) << 31)) {
    bits = ordinal ^ (uint32_t(1) << 31);
  } else {
    bits = ~ordinal;
  }

  float result;
  std::memcpy(&result, &bits, sizeof(float));
  return result;
}

double herbie::hyperrectWeight(const Hyperrect &rect,
                               llvm::ArrayRef<unsigned> floatBitWidths) {
  if (rect.size() != floatBitWidths.size())
    return 0.0;

  double weight = 1.0;
  for (size_t i = 0; i < rect.size(); ++i) {
    double lo = rect[i].loAsDouble();
    double hi = rect[i].hiAsDouble();

    uint64_t loOrd, hiOrd;
    if (floatBitWidths[i] == 32) {
      loOrd = floatToOrdinal(static_cast<float>(lo));
      hiOrd = floatToOrdinal(static_cast<float>(hi));
    } else {
      loOrd = floatToOrdinal(lo);
      hiOrd = floatToOrdinal(hi);
    }

    // +1 because both endpoints are inclusive
    double dimWeight = static_cast<double>(hiOrd - loOrd + 1);
    weight *= dimWeight;
  }
  return weight;
}

double herbie::totalWeight(llvm::ArrayRef<unsigned> floatBitWidths) {
  double weight = 1.0;
  for (unsigned bitWidth : floatBitWidths) {
    weight *= totalOrdinals(bitWidth);
  }
  return weight;
}

// ============================================================================
// Hyperrectangle Creation
// ============================================================================

Hyperrect herbie::createFullDomainRect(llvm::ArrayRef<unsigned> floatBitWidths,
                                       unsigned precision) {
  Hyperrect rect;
  rect.reserve(floatBitWidths.size());

  for (unsigned bitWidth : floatBitWidths) {
    if (bitWidth == 32) {
      rect.emplace_back(-std::numeric_limits<float>::max(),
                        std::numeric_limits<float>::max(), precision);
    } else {
      rect.emplace_back(-std::numeric_limits<double>::max(),
                        std::numeric_limits<double>::max(), precision);
    }
  }
  return rect;
}

Hyperrect herbie::createRect(llvm::ArrayRef<std::pair<double, double>> bounds,
                             unsigned precision) {
  Hyperrect rect;
  rect.reserve(bounds.size());
  for (const auto &[lo, hi] : bounds) {
    rect.emplace_back(lo, hi, precision);
  }
  return rect;
}

// ============================================================================
// Midpoint Finding
// ============================================================================

std::optional<MidpointResult> herbie::findMidpoints(const Interval &interval,
                                                    unsigned floatBitWidth) {
  double lo = interval.loAsDouble();
  double hi = interval.hiAsDouble();

  if (floatBitWidth == 32) {
    uint32_t loOrd = floatToOrdinal(static_cast<float>(lo));
    uint32_t hiOrd = floatToOrdinal(static_cast<float>(hi));

    // Need at least 2 gap to split (so we can have distinct lo/hi regions)
    if (hiOrd - loOrd < 2)
      return std::nullopt;

    uint32_t midOrd = loOrd + (hiOrd - loOrd) / 2;
    return MidpointResult{ordinalToFloat32(midOrd),
                          ordinalToFloat32(midOrd + 1)};
  } else {
    assert(floatBitWidth == 64);
    uint64_t loOrd = floatToOrdinal(lo);
    uint64_t hiOrd = floatToOrdinal(hi);

    if (hiOrd - loOrd < 2)
      return std::nullopt;

    uint64_t midOrd = loOrd + (hiOrd - loOrd) / 2;
    return MidpointResult{ordinalToFloat64(midOrd),
                          ordinalToFloat64(midOrd + 1)};
  }
}

// ============================================================================
// RivalRectArgs
// ============================================================================

RivalRectArgs::RivalRectArgs(const Hyperrect &rect) {
  // Rival expects [lo0, hi0, lo1, hi1, ...] as pairs
  ptrs_.reserve(rect.size() * 2);
  for (const auto &interval : rect) {
    ptrs_.push_back(&interval.lo());
    ptrs_.push_back(&interval.hi());
  }
}

RivalRectArgs::~RivalRectArgs() = default;

// ============================================================================
// Search Step
// ============================================================================

void herbie::searchStep(RivalMachine *machine, SearchSpace &space,
                        unsigned splitDimension,
                        llvm::ArrayRef<unsigned> floatBitWidths) {
  std::vector<RegionWithHints> newOther;
  newOther.reserve(space.otherRegions.size() * 2);

  for (auto &region : space.otherRegions) {
    RivalRectArgs args(region.rect);

    RivalAnalyzeResult result = rival_analyze_with_hints(
        machine, args.data(), region.rect.size(), region.hints.get());

    if (result.error != RIVAL_ERROR_OK &&
        result.error != RIVAL_ERROR_UNSAMPLABLE) {
      // Unexpected error - treat as false region
      space.falseRegions.push_back(std::move(region));
      if (result.hints)
        rival_hints_free(result.hints);
      continue;
    }

    if (result.is_error) {
      // Definitely an error region
      space.falseRegions.push_back(std::move(region));
      if (result.hints)
        rival_hints_free(result.hints);
    } else if (!result.maybe_error && result.converged) {
      // Definitely valid region
      region.hints.reset(result.hints);
      space.trueRegions.push_back(std::move(region));
    } else {
      // Uncertain - try to subdivide
      auto midpoints = findMidpoints(region.rect[splitDimension],
                                     floatBitWidths[splitDimension]);

      if (midpoints) {
        // Create two sub-regions by splitting on the given dimension
        Hyperrect loRect = region.rect;
        Hyperrect hiRect = region.rect;

        loRect[splitDimension].setHi(midpoints->loMid);
        hiRect[splitDimension].setLo(midpoints->hiMid);

        // Transfer hints to both (they'll be refined on next analysis)
        // Note: we can't share hints, so we only give hints to one
        newOther.emplace_back(std::move(loRect), result.hints);
        newOther.emplace_back(std::move(hiRect), nullptr);
      } else {
        // Can't split further - keep as uncertain
        region.hints.reset(result.hints);
        newOther.push_back(std::move(region));
      }
    }
  }

  space.otherRegions = std::move(newOther);
}

// ============================================================================
// Statistics Computation
// ============================================================================

SamplingTable
herbie::computeStatistics(const SearchSpace &space,
                          llvm::ArrayRef<unsigned> floatBitWidths) {
  SamplingTable table;
  double total = totalWeight(floatBitWidths);

  if (total == 0)
    return table;

  double validWeight = 0;
  for (const auto &region : space.trueRegions) {
    validWeight += hyperrectWeight(region.rect, floatBitWidths);
  }

  double invalidWeight = 0;
  for (const auto &region : space.falseRegions) {
    invalidWeight += hyperrectWeight(region.rect, floatBitWidths);
  }

  double unknownWeight = 0;
  for (const auto &region : space.otherRegions) {
    unknownWeight += hyperrectWeight(region.rect, floatBitWidths);
  }

  table.validFraction = validWeight / total;
  table.invalidFraction = invalidWeight / total;
  table.unknownFraction = unknownWeight / total;
  table.preconditionFraction = 0; // Future: precondition support

  return table;
}

// ============================================================================
// Main Search Algorithm
// ============================================================================

SearchResult herbie::findIntervals(RivalMachine *machine,
                                   llvm::ArrayRef<Hyperrect> initialRects,
                                   llvm::ArrayRef<unsigned> floatBitWidths,
                                   const IntervalSearchOptions &options) {
  SearchSpace space;

  // Initialize with the input rectangles as "other" (undetermined)
  space.otherRegions.reserve(initialRects.size());
  for (const auto &rect : initialRects) {
    // Deep copy the rect
    Hyperrect copy;
    copy.reserve(rect.size());
    for (const auto &interval : rect) {
      copy.push_back(interval);
    }
    space.otherRegions.emplace_back(std::move(copy), nullptr);
  }

  unsigned numVars = floatBitWidths.size();

  // Main search loop
  for (unsigned n = 0; n < options.maxSearchDepth; ++n) {
    if (space.otherRegions.empty())
      break;

    size_t totalRegions = space.trueRegions.size() + space.falseRegions.size() +
                          space.otherRegions.size();
    if (totalRegions >= options.maxRegions)
      break;

    unsigned splitDim = n % numVars;
    searchStep(machine, space, splitDim, floatBitWidths);
  }

  // Build result: sampleable = true ∪ other
  SearchResult result;
  result.statistics = computeStatistics(space, floatBitWidths);
  result.sampleableRegions.reserve(space.trueRegions.size() +
                                   space.otherRegions.size());

  for (auto &region : space.trueRegions) {
    result.sampleableRegions.push_back(std::move(region));
  }
  for (auto &region : space.otherRegions) {
    result.sampleableRegions.push_back(std::move(region));
  }

  return result;
}

// ============================================================================
// runIntervalSearchOnFunction Implementation
// ============================================================================

FunctionIntervalResult
herbie::runIntervalSearchOnFunction(mlir::func::FuncOp funcOp,
                                    const IntervalSearchConfig &config) {
  TAMAGOYAKI_SCOPED_TIMER("runIntervalSearchOnFunction");
  FunctionIntervalResult result;
  result.success = false;

  auto iface = mlir::dyn_cast<RivalCompileableInterface>(funcOp.getOperation());
  if (!iface) {
    funcOp.emitWarning()
        << "Function does not implement RivalCompileableInterface";
    return result;
  }

  RivalExprArena *arena = rival_expr_arena_new();
  if (!arena) {
    funcOp.emitError() << "Failed to create Rival expression arena";
    return result;
  }

  auto exprs = iface.compile(arena, {});
  if (exprs.size() != 1) {
    funcOp->emitError()
        << "Currently, only functions with a single result are supported.";
    return result;
  }
  uint32_t exprRoot = exprs[0];

  size_t numArgs = funcOp.getNumArguments();
  std::vector<std::string> varNames;
  std::vector<const char *> varNamePtrs;

  varNames.reserve(numArgs);
  result.floatBitWidths.reserve(numArgs);

  for (size_t i = 0; i < numArgs; ++i) {
    varNames.push_back("arg" + std::to_string(i));

    mlir::Type argType = funcOp.getArgumentTypes()[i];
    if (auto floatType = mlir::dyn_cast<mlir::FloatType>(argType)) {
      result.floatBitWidths.push_back(floatType.getWidth());
    } else {
      funcOp.emitError() << "Argument " << i << " is not a floating-point type";
      rival_expr_arena_free(arena);
      return result;
    }
  }

  varNamePtrs.reserve(varNames.size());
  for (auto &name : varNames) {
    varNamePtrs.push_back(name.c_str());
  }

  uint32_t roots[] = {exprRoot};

  RivalDiscretization *disc = nullptr;
  if (funcOp.getNumResults() > 0) {
    mlir::Type resultType = funcOp.getResultTypes()[0];
    if (auto floatType = mlir::dyn_cast<mlir::FloatType>(resultType)) {
      if (floatType.getWidth() == 32)
        disc = rival_disc_f32(24);
      else
        disc = rival_disc_f64(53);
    }
  }
  if (!disc)
    disc = rival_disc_f64(53);

  RivalMachine *machine =
      rival_machine_new(arena, roots, 1, varNamePtrs.data(), numArgs, disc,
                        config.maxRivalPrecision, 1000);

  if (!machine) {
    funcOp.emitError() << "Failed to create Rival machine";
    rival_disc_free(disc);
    rival_expr_arena_free(arena);
    return result;
  }

  IntervalSearchOptions options;
  options.maxSearchDepth = config.maxSearchDepth;
  options.maxRegions = config.maxRegions;
  options.analysisPrecision = config.analysisPrecision;
  options.maxRivalPrecision = config.maxRivalPrecision;
  options.maxRivalIterations = config.maxRivalIterations;
  options.emitStatistics = false;

  std::vector<Hyperrect> initialRects;
  initialRects.push_back(
      createFullDomainRect(result.floatBitWidths, config.analysisPrecision));

  result.searchResult =
      findIntervals(machine, initialRects, result.floatBitWidths, options);
  result.success = true;

  rival_machine_free(machine);
  rival_disc_free(disc);
  rival_expr_arena_free(arena);

  return result;
}

// ============================================================================
// Sampling
// ============================================================================

namespace {

size_t weightedBinarySearch(llvm::ArrayRef<double> cumulativeWeights,
                            double target) {
  size_t left = 0;
  size_t right = cumulativeWeights.size() - 1;
  while (left < right) {
    size_t mid = left + (right - left) / 2;
    if (cumulativeWeights[mid] <= target)
      left = mid + 1;
    else
      right = mid;
  }
  return left;
}

} // namespace

llvm::SmallVector<double>
herbie::buildCumulativeWeights(llvm::ArrayRef<RegionWithHints> regions,
                               llvm::ArrayRef<unsigned> floatBitWidths) {
  llvm::SmallVector<double> cumWeights;
  cumWeights.reserve(regions.size());
  double running = 0.0;
  for (const auto &region : regions) {
    running += hyperrectWeight(region.rect, floatBitWidths);
    cumWeights.push_back(running);
  }
  return cumWeights;
}

std::pair<std::vector<double>, size_t>
herbie::samplePoint(llvm::ArrayRef<RegionWithHints> regions,
                    llvm::ArrayRef<double> cumulativeWeights,
                    llvm::ArrayRef<unsigned> floatBitWidths,
                    std::mt19937_64 &rng) {
  double totalW = cumulativeWeights.back();
  std::uniform_real_distribution<double> weightDist(0.0, totalW);
  double pick = weightDist(rng);

  size_t idx = weightedBinarySearch(cumulativeWeights, pick);
  idx = std::min(idx, regions.size() - 1);

  const Hyperrect &rect = regions[idx].rect;
  size_t numVars = floatBitWidths.size();
  std::vector<double> point(numVars);

  for (size_t d = 0; d < numVars; ++d) {
    double lo = rect[d].loAsDouble();
    double hi = rect[d].hiAsDouble();

    if (floatBitWidths[d] == 32) {
      uint32_t loOrd = floatToOrdinal(static_cast<float>(lo));
      uint32_t hiOrd = floatToOrdinal(static_cast<float>(hi));
      std::uniform_int_distribution<uint32_t> dist(loOrd, hiOrd);
      point[d] = static_cast<double>(ordinalToFloat32(dist(rng)));
    } else {
      uint64_t loOrd = floatToOrdinal(lo);
      uint64_t hiOrd = floatToOrdinal(hi);
      std::uniform_int_distribution<uint64_t> dist(loOrd, hiOrd);
      point[d] = ordinalToFloat64(dist(rng));
    }
  }

  return {point, idx};
}

SamplingResult herbie::sampleAndEvaluate(
    const RivalExprArena *arena, llvm::ArrayRef<uint32_t> roots,
    llvm::ArrayRef<const char *> varNames, const RivalDiscretization *disc,
    const SearchResult &searchResult, llvm::ArrayRef<unsigned> floatBitWidths,
    unsigned numSamples, unsigned evalMaxIterations, unsigned evalMaxPrecision,
    unsigned analysisPrecision, uint64_t seed) {
  SamplingResult sr;
  size_t numRoots = roots.size();

  auto &regions = searchResult.sampleableRegions;
  if (regions.empty())
    return sr;

  // Build one RivalMachine per root so that a failure in one expression
  // (e.g. division by zero) does not discard the entire sample point.
  std::vector<RivalMachine *> machines(numRoots, nullptr);
  size_t numVars = varNames.size();

  for (size_t r = 0; r < numRoots; ++r) {
    uint32_t root = roots[r];
    machines[r] = rival_machine_new(arena, &root, 1, varNames.data(), numVars,
                                    disc, evalMaxPrecision, 1000);
  }

  auto cumWeights = buildCumulativeWeights(regions, floatBitWidths);
  std::mt19937_64 rng(seed);

  sr.points.resize(numSamples);
  sr.results.resize(numSamples, std::vector<double>(numRoots));

  auto *argMpfr = new mpfr_t[numVars];
  std::vector<const mpfr_t *> argPtrs(numVars);
  for (size_t i = 0; i < numVars; ++i) {
    mpfr_init2(argMpfr[i], analysisPrecision);
    argPtrs[i] = &argMpfr[i];
  }

  mpfr_t outMpfr;
  mpfr_init2(outMpfr, analysisPrecision);
  mpfr_t *outPtr = &outMpfr;

  for (unsigned s = 0; s < numSamples; ++s) {
    auto [pt, regionIdx] =
        samplePoint(regions, cumWeights, floatBitWidths, rng);

    for (size_t d = 0; d < numVars; ++d)
      mpfr_set_d(argMpfr[d], pt[d], MPFR_RNDN);

    sr.points[s] = std::move(pt);

    for (size_t r = 0; r < numRoots; ++r) {
      if (!machines[r]) {
        sr.results[s][r] = std::numeric_limits<double>::quiet_NaN();
        continue;
      }

      RivalError err =
          rival_apply(machines[r], argPtrs.data(), numVars, &outPtr, 1, nullptr,
                      evalMaxIterations, evalMaxPrecision);

      if (err != RIVAL_ERROR_OK || !mpfr_number_p(outMpfr)) {
        sr.results[s][r] = std::numeric_limits<double>::quiet_NaN();
      } else {
        sr.results[s][r] = mpfr_get_d(outMpfr, MPFR_RNDN);
      }
    }
  }

  sr.sampled = numSamples;

  mpfr_clear(outMpfr);
  for (size_t i = 0; i < numVars; ++i)
    mpfr_clear(argMpfr[i]);
  delete[] argMpfr;

  for (size_t r = 0; r < numRoots; ++r) {
    if (machines[r])
      rival_machine_free(machines[r]);
  }

  return sr;
}
