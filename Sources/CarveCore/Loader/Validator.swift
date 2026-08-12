// Sources/CarveCore/Loader/Validator.swift

/// Returns a list of human-readable problems. Empty means valid.
/// Never throws — the caller decides how to present failures.
public func validateCase(_ c: CaseFile) -> [String] {
  var problems: [String] = []

  var seenSectorIds = Set<String>()
  for entry in c.sectorMap {
    if !seenSectorIds.insert(entry.fragmentId).inserted {
      problems.append("Duplicate sector entry for \"\(entry.fragmentId)\".")
    }
    if c.fragments[entry.fragmentId] == nil {
      problems.append("Sector entry \"\(entry.fragmentId)\" has no fragment file.")
    }
    if entry.integrity < 0 || entry.integrity > 1 {
      problems.append("Sector entry \"\(entry.fragmentId)\" integrity must be 0..1.")
    }
  }

  // Parse every hiddenUntil; collect grammar / reference problems early.
  var parsedGates: [String: any Predicate] = [:]
  for id in c.fragments.keys.sorted() {
    guard let fragment = c.fragments[id], let raw = fragment.hiddenUntil else { continue }
    do {
      let predicate = try parsePredicate(raw)
      parsedGates[id] = predicate
      for ref in allCarvedReferences(predicate) where c.fragments[ref] == nil {
        problems.append(
          "Fragment \"\(id)\" hiddenUntil references unknown fragment \"\(ref)\".")
      }
      for ref in allAnsweredReferences(predicate) where !c.questions.contains(where: { $0.id == ref }) {
        problems.append(
          "Fragment \"\(id)\" hiddenUntil references unknown question \"\(ref)\".")
      }
    } catch let error as PredicateFormatError {
      problems.append("Fragment \"\(id)\" hiddenUntil is not valid declarative grammar: \(error.message)")
    } catch {
      problems.append("Fragment \"\(id)\" hiddenUntil is not valid declarative grammar: \(error)")
    }
  }

  // Deadlock: A hidden until B, B hidden until A (or longer cycles).
  do {
    if try hasUnlockCycle(fragments: c.fragments) {
      problems.append(
        "Unlock cycle detected: two or more fragments gate each other via hiddenUntil. "
          + "The player can never open them.")
    }
  } catch let error as PredicateFormatError {
    // Already reported per-fragment above when parsing failed.
    _ = error
  } catch {
    problems.append("Unlock cycle check failed: \(error)")
  }

  // INV-4: every fragment is reachable from the sector map through some
  // sequence of unlocks. Sector map alone is not the only path.
  let reachable: Set<String>
  do {
    reachable = try reachableFragmentIds(sectorMap: c.sectorMap, fragments: c.fragments)
  } catch {
    reachable = Set(c.sectorMap.map(\.fragmentId))
  }

  for id in c.fragments.keys.sorted() {
    if !reachable.contains(id) {
      let hasGate = c.fragments[id]?.hiddenUntil != nil
      if hasGate {
        problems.append(
          "INV-4 violated: fragment \"\(id)\" is unreachable — its hiddenUntil can never "
            + "become true from the sector map.")
      } else {
        problems.append(
          "INV-4 violated: fragment \"\(id)\" is unreachable — not on the sector map and "
            + "has no hiddenUntil gate.")
      }
    }
  }

  // Verdict questions.
  var seenQuestionIds = Set<String>()
  for question in c.questions {
    if !seenQuestionIds.insert(question.id).inserted {
      problems.append("Duplicate verdict question id \"\(question.id)\".")
    }
    if !question.options.contains(question.correct) {
      problems.append(
        "Question \"\(question.id)\" has correct answer \"\(question.correct)\" which is "
          + "not among its options [\(question.options.joined(separator: ", "))].")
    }
    if question.supportedBy.isEmpty {
      problems.append(
        "INV-3 violated: question \"\(question.id)\" lists no supporting fragments.")
    }
    for fragmentId in question.supportedBy {
      if c.fragments[fragmentId] == nil {
        problems.append(
          "INV-3 violated: question \"\(question.id)\" is supported by \"\(fragmentId)\", "
            + "which does not exist.")
      } else if !reachable.contains(fragmentId) {
        problems.append(
          "INV-3 violated: question \"\(question.id)\" is supported by \"\(fragmentId)\", "
            + "which is not reachable through any unlock sequence.")
      }
    }
  }

  if c.questions.isEmpty {
    problems.append("A case needs at least one verdict question.")
  }

  // DR-13: every fragment surface must be a known type/surface pair.
  for id in c.fragments.keys.sorted() {
    guard let fragment = c.fragments[id] else { continue }
    if !ContentSurface.isAllowed(
      type: fragment.type,
      surface: fragment.surface,
      recordKind: fragment.recordKind)
    {
      let kindText = fragment.recordKind.map { " kind=\($0)" } ?? ""
      problems.append(
        "Fragment \"\(id)\" has invalid type/surface combination: "
          + "type=\(fragment.type.rawValue)\(kindText) surface=\(fragment.surface.rawValue).")
    }
  }

  return problems
}
