// Sources/CarveCore/Loader/Validator.swift

/// Returns a list of human-readable problems. Empty means valid.
/// Never throws — the caller decides how to present failures.
public func validateCase(_ c: CaseFile) -> [String] {
  var problems: [String] = []

  // Every sector entry must resolve to a fragment.
  var seenSectorIds = Set<String>()
  for entry in c.sectorMap {
    if !seenSectorIds.insert(entry.fragmentId).inserted {
      problems.append("Duplicate sector entry for \"\(entry.fragmentId)\".")
    }
    if c.fragments[entry.fragmentId] == nil {
      problems.append("Sector entry \"\(entry.fragmentId)\" has no fragment file.")
    }
    if entry.carveCost <= 0 {
      problems.append("Sector entry \"\(entry.fragmentId)\" has carveCost <= 0.")
    }
    if entry.integrity < 0 || entry.integrity > 1 {
      problems.append("Sector entry \"\(entry.fragmentId)\" integrity must be 0..1.")
    }
  }

  // INV-4: no orphan fragments.
  var referenced = Set<String>()
  for entry in c.sectorMap {
    referenced.insert(entry.fragmentId)
  }
  for id in c.fragments.keys.sorted() {
    if !referenced.contains(id) {
      problems.append(
        "INV-4 violated: fragment \"\(id)\" is unreachable — no sector entry references it.")
    }
  }

  // INV-2: the case must NOT be fully recoverable within budget.
  if c.totalCarveCost <= c.cycleBudget {
    problems.append(
      "INV-2 violated: total carve cost (\(c.totalCarveCost)) is within cycleBudget "
        + "(\(c.cycleBudget)). The player could recover everything, which removes every "
        + "decision from the case.")
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
      }
    }
  }

  if c.questions.isEmpty {
    problems.append("A case needs at least one verdict question.")
  }

  if !isSolvable(c) {
    problems.append(
      "INV-1 violated: no set of fragments within cycleBudget (\(c.cycleBudget)) supports "
        + "every verdict question. The case is unwinnable.")
  }

  return problems
}
