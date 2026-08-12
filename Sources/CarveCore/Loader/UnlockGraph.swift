// Sources/CarveCore/Loader/UnlockGraph.swift

/// Fixed-point set of fragments a player can eventually open, assuming free
/// link/answer actions and free carving of anything currently visible.
///
/// Links and answers are player choices with no resource cost, so positive
/// `linked` / `answered` leaves are treated as openable. Positive `carved`
/// leaves require the target to already be in the reachable set. `not` is
/// handled existentially via `canFalsify` (the player may refuse a free action).
///
/// Sector-map membership alone does not make a gated fragment reachable — its
/// `hiddenUntil` must become true through some unlock sequence.
public func reachableFragmentIds(
  sectorMap: [SectorEntry],
  fragments: [String: Fragment]
) throws -> Set<String> {
  var reachable = Set<String>()

  // Seed: sector-map fragments with no gate, or a gate already open on empty state.
  for entry in sectorMap {
    guard let fragment = fragments[entry.fragmentId] else { continue }
    if let raw = fragment.hiddenUntil {
      let predicate = try parsePredicate(raw)
      if canOpen(predicate, reachable: []) {
        reachable.insert(entry.fragmentId)
      }
    } else {
      reachable.insert(entry.fragmentId)
    }
  }

  var progress = true
  while progress {
    progress = false
    for (id, fragment) in fragments {
      if reachable.contains(id) { continue }
      guard let raw = fragment.hiddenUntil else { continue }
      let predicate = try parsePredicate(raw)
      if canOpen(predicate, reachable: reachable) {
        reachable.insert(id)
        progress = true
      }
    }
  }
  return reachable
}

/// True when the unlock dependency graph has a cycle among positive `carved`
/// edges (A hidden until B is carved, B hidden until A is carved, …).
public func hasUnlockCycle(fragments: [String: Fragment]) throws -> Bool {
  var adjacency: [String: Set<String>] = [:]
  for (id, fragment) in fragments {
    guard let raw = fragment.hiddenUntil else { continue }
    let predicate = try parsePredicate(raw)
    let deps = positiveCarvedDependencies(predicate)
    if !deps.isEmpty {
      adjacency[id] = deps
    }
  }

  var visiting = Set<String>()
  var visited = Set<String>()

  func dfs(_ node: String) -> Bool {
    if visiting.contains(node) { return true }
    if visited.contains(node) { return false }
    visiting.insert(node)
    for dep in adjacency[node] ?? [] {
      if dfs(dep) { return true }
    }
    visiting.remove(node)
    visited.insert(node)
    return false
  }

  for node in adjacency.keys {
    if dfs(node) { return true }
  }
  return false
}

/// Positive `carved` ids under `all`/`any`. `not` contributes nothing — a
/// negated carve is not a "must open first" edge for deadlock detection.
func positiveCarvedDependencies(_ predicate: any Predicate) -> Set<String> {
  if let carved = predicate as? CarvedPredicate {
    return [carved.fragmentId]
  }
  if predicate is LinkedPredicate || predicate is AnsweredPredicate {
    return []
  }
  if let all = predicate as? AllPredicate {
    return all.children.reduce(into: Set()) { $0.formUnion(positiveCarvedDependencies($1)) }
  }
  if let any = predicate as? AnyPredicate {
    return any.children.reduce(into: Set()) { $0.formUnion(positiveCarvedDependencies($1)) }
  }
  if predicate is NotPredicate {
    return []
  }
  return []
}

func canOpen(_ predicate: any Predicate, reachable: Set<String>) -> Bool {
  if let carved = predicate as? CarvedPredicate {
    return reachable.contains(carved.fragmentId)
  }
  if predicate is LinkedPredicate || predicate is AnsweredPredicate {
    return true
  }
  if let all = predicate as? AllPredicate {
    return all.children.allSatisfy { canOpen($0, reachable: reachable) }
  }
  if let any = predicate as? AnyPredicate {
    return any.children.contains { canOpen($0, reachable: reachable) }
  }
  if let not = predicate as? NotPredicate {
    return canFalsify(not.child, reachable: reachable)
  }
  return false
}

/// Whether the player can make `predicate` false using only free choices and
/// carving (or not) from `reachable`.
func canFalsify(_ predicate: any Predicate, reachable: Set<String>) -> Bool {
  if predicate is CarvedPredicate {
    return true
  }
  if predicate is LinkedPredicate || predicate is AnsweredPredicate {
    return true
  }
  if let all = predicate as? AllPredicate {
    return all.children.contains { canFalsify($0, reachable: reachable) }
  }
  if let any = predicate as? AnyPredicate {
    return any.children.allSatisfy { canFalsify($0, reachable: reachable) }
  }
  if let not = predicate as? NotPredicate {
    return canOpen(not.child, reachable: reachable)
  }
  return false
}

/// Every fragment id named by a `carved` leaf, including under `not`.
func allCarvedReferences(_ predicate: any Predicate) -> Set<String> {
  if let carved = predicate as? CarvedPredicate {
    return [carved.fragmentId]
  }
  if predicate is LinkedPredicate || predicate is AnsweredPredicate {
    return []
  }
  if let all = predicate as? AllPredicate {
    return all.children.reduce(into: Set()) { $0.formUnion(allCarvedReferences($1)) }
  }
  if let any = predicate as? AnyPredicate {
    return any.children.reduce(into: Set()) { $0.formUnion(allCarvedReferences($1)) }
  }
  if let not = predicate as? NotPredicate {
    return allCarvedReferences(not.child)
  }
  return []
}

func allAnsweredReferences(_ predicate: any Predicate) -> Set<String> {
  if let answered = predicate as? AnsweredPredicate {
    return [answered.questionId]
  }
  if predicate is CarvedPredicate || predicate is LinkedPredicate {
    return []
  }
  if let all = predicate as? AllPredicate {
    return all.children.reduce(into: Set()) { $0.formUnion(allAnsweredReferences($1)) }
  }
  if let any = predicate as? AnyPredicate {
    return any.children.reduce(into: Set()) { $0.formUnion(allAnsweredReferences($1)) }
  }
  if let not = predicate as? NotPredicate {
    return allAnsweredReferences(not.child)
  }
  return []
}
