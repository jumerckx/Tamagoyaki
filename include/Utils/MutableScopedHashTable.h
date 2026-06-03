// MutableScopedHashTable.h - Tree-based scoping

#ifndef MUTABLE_SCOPED_HASH_TABLE_H
#define MUTABLE_SCOPED_HASH_TABLE_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseMapInfo.h"
#include "llvm/Support/AllocatorBase.h"
#include <cassert>
#include <memory>
#include <optional>

namespace mlir::ematch {

template <typename K, typename V, typename KInfo = llvm::DenseMapInfo<K>,
          typename AllocatorTy = llvm::MallocAllocator>
class MutableScopedHashTable;

template <typename K, typename V> class MutableScopedHashTableVal {
  K Key;
  V Val;

  MutableScopedHashTableVal(const K &key, const V &val) : Key(key), Val(val) {}

  template <typename, typename, typename, typename>
  friend class MutableScopedHashTableScope;

public:
  const K &getKey() const { return Key; }
  const V &getValue() const { return Val; }
  V &getValue() { return Val; }

  template <typename AllocatorTy>
  static MutableScopedHashTableVal *Create(const K &key, const V &val,
                                           AllocatorTy &Allocator) {
    auto *New = Allocator.template Allocate<MutableScopedHashTableVal>();
    new (New) MutableScopedHashTableVal(key, val);
    return New;
  }

  template <typename AllocatorTy> void Destroy(AllocatorTy &Allocator) {
    this->~MutableScopedHashTableVal();
    Allocator.Deallocate(this);
  }
};

template <typename K, typename V, typename KInfo = llvm::DenseMapInfo<K>,
          typename AllocatorTy = llvm::MallocAllocator>
class MutableScopedHashTableScope {
public:
  using ValTy = MutableScopedHashTableVal<K, V>;
  using TableTy = MutableScopedHashTable<K, V, KInfo, AllocatorTy>;

private:
  TableTy &HT;
  MutableScopedHashTableScope *ParentScope;

  // Local map for THIS scope's bindings only
  llvm::DenseMap<K, ValTy *, KInfo> LocalMap;

public:
  /// Create a root scope (no parent)
  explicit MutableScopedHashTableScope(TableTy &ht)
      : HT(ht), ParentScope(nullptr) {}

  /// Create a child scope with explicit parent
  MutableScopedHashTableScope(TableTy &ht, MutableScopedHashTableScope *parent)
      : HT(ht), ParentScope(parent) {}

  MutableScopedHashTableScope(const MutableScopedHashTableScope &) = delete;
  MutableScopedHashTableScope &
  operator=(const MutableScopedHashTableScope &) = delete;

  ~MutableScopedHashTableScope() {
    // Clean up all values in this scope
    for (auto &[_k, v] : LocalMap) {
      v->Destroy(HT.getAllocator());
    }
  }

  MutableScopedHashTableScope *getParentScope() { return ParentScope; }
  const MutableScopedHashTableScope *getParentScope() const {
    return ParentScope;
  }

  /// Insert a key-value pair into THIS scope
  void insert(const K &Key, const V &Val) {
    ValTy *NewVal = ValTy::Create(Key, Val, HT.getAllocator());
    LocalMap[Key] = NewVal;
  }

  /// Lookup a key, searching this scope and all ancestors
  std::optional<V> lookup(const K &Key) const {
    // Search this scope first
    auto it = LocalMap.find(Key);
    if (it != LocalMap.end())
      return it->second->getValue();

    // Recurse to parent
    if (ParentScope)
      return ParentScope->lookup(Key);

    return std::nullopt;
  }

  /// Lookup returning default value if not found
  V lookupOrDefault(const K &Key) const {
    auto result = lookup(Key);
    return result ? *result : V();
  }

  /// Check if key exists in this scope or ancestors
  bool count(const K &Key) const { return lookup(Key).has_value(); }

  /// Check if key exists in THIS scope only (not ancestors)
  bool countLocal(const K &Key) const { return LocalMap.count(Key); }

  /// Erase from THIS scope only. Returns true if found and erased.
  bool erase(const K &Key) {
    auto it = LocalMap.find(Key);
    if (it == LocalMap.end())
      return false;

    ValTy *Entry = it->second;
    LocalMap.erase(it);

    Entry->Destroy(HT.getAllocator());
    return true;
  }

  /// Get mutable reference to value (searches ancestors)
  /// Returns nullptr if not found
  V *lookupMutable(const K &Key) {
    auto it = LocalMap.find(Key);
    if (it != LocalMap.end())
      return &it->second->getValue();

    if (ParentScope)
      return ParentScope->lookupMutable(Key);

    return nullptr;
  }
};

template <typename K, typename V, typename KInfo, typename AllocatorTy>
class MutableScopedHashTable : llvm::detail::AllocatorHolder<AllocatorTy> {
  using AllocTy = llvm::detail::AllocatorHolder<AllocatorTy>;

public:
  using ScopeTy = MutableScopedHashTableScope<K, V, KInfo, AllocatorTy>;
  using ValTy = MutableScopedHashTableVal<K, V>;

  friend class MutableScopedHashTableScope<K, V, KInfo, AllocatorTy>;

  MutableScopedHashTable() = default;
  MutableScopedHashTable(const MutableScopedHashTable &) = delete;
  MutableScopedHashTable &operator=(const MutableScopedHashTable &) = delete;

  using AllocTy::getAllocator;

  /// Create a root scope
  [[nodiscard]] std::unique_ptr<ScopeTy> createRootScope() {
    return std::make_unique<ScopeTy>(*this);
  }

  /// Create a child scope from a parent
  [[nodiscard]] std::unique_ptr<ScopeTy> createChildScope(ScopeTy *parent) {
    return std::make_unique<ScopeTy>(*this, parent);
  }
};

} // namespace mlir::ematch

#endif // MUTABLE_SCOPED_HASH_TABLE_H
