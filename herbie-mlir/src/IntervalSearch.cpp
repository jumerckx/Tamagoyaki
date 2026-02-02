#include "IntervalSearch.h"
#include "rival.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <optional>
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
