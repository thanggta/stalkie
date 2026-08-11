// Sources/CarveCore/Loader/Solver.swift

/// True when some set of fragments costing <= cycleBudget supports every
/// verdict question. Exact branch-and-bound over questions; case sizes are
/// small (tens of fragments, <= 6 questions).
public func isSolvable(_ c: CaseFile) -> Bool {
  var costOf: [String: Int] = [:]
  for sector in c.sectorMap {
    costOf[sector.fragmentId] = sector.carveCost
  }

  // Any question with no reachable supporting fragment is unsolvable outright.
  for question in c.questions {
    let reachable = question.supportedBy.filter { costOf[$0] != nil }
    if reachable.isEmpty { return false }
  }

  var best = 1_073_741_824

  func search(_ index: Int, _ carved: inout Set<String>, _ spent: Int) {
    if spent >= best || spent > c.cycleBudget { return }
    if index == c.questions.count {
      best = spent
      return
    }
    let question = c.questions[index]
    // Already satisfied by a fragment carved for an earlier question.
    if question.supportedBy.contains(where: { carved.contains($0) }) {
      search(index + 1, &carved, spent)
      return
    }
    for fragmentId in question.supportedBy {
      guard let cost = costOf[fragmentId] else { continue }
      carved.insert(fragmentId)
      search(index + 1, &carved, spent + cost)
      carved.remove(fragmentId)
    }
  }

  var carved = Set<String>()
  search(0, &carved, 0)
  return best <= c.cycleBudget
}
