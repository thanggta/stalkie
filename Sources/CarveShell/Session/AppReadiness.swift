// Sources/CarveShell/Session/AppReadiness.swift
// Diegetic Links / Decide. Generic — no case ids, no fragment ids in Swift.
// DR-14: Links is a state threshold; Decide is an optional six-predicate.

import Foundation
import CarveCore

public enum AppReadiness {
  /// Links appears once two named people exist in carved content.
  public static func linksReady(entities: [BoardEntity]) -> Bool {
    entities.count >= 2
  }

  /// Decide uses `decideReadyWhen` when authored. Otherwise it appears after
  /// any verdict-supporting fragment has been recovered. `answered` is
  /// forbidden in the authored predicate so hiding Decide cannot deadlock.
  public static func decideReady(caseFile: CaseFile, state: GameState) -> Bool {
    if let raw = caseFile.decideReadyWhen {
      guard let predicate = try? parsePredicate(raw) else { return false }
      return predicate.evaluate(state)
    }
    return caseFile.questions.contains { question in
      question.supportedBy.contains { state.carvedFragmentIds.contains($0) }
    }
  }

  public static func validateDecideReadiness(_ caseFile: CaseFile) -> [String] {
    guard let raw = caseFile.decideReadyWhen else { return [] }
    var problems: [String] = []
    let predicate: any CarveCore.Predicate
    do {
      predicate = try parsePredicate(raw)
    } catch {
      return ["decideReadyWhen is not valid declarative grammar: \(error)"]
    }

    if !allAnsweredReferences(predicate).isEmpty {
      problems.append(
        "decideReadyWhen cannot use \"answered\" — that would hide Decide until "
          + "questions are filed, which is a deadlock.")
    }
    for ref in allCarvedReferences(predicate) where caseFile.fragments[ref] == nil {
      problems.append("decideReadyWhen references unknown fragment \"\(ref)\".")
    }

    let reachable: Set<String>
    do {
      reachable = try reachableFragmentIds(
        sectorMap: caseFile.sectorMap,
        fragments: caseFile.fragments)
    } catch {
      return problems
    }
    for ref in allCarvedReferences(predicate) where !reachable.contains(ref) {
      problems.append(
        "decideReadyWhen references unreachable fragment \"\(ref)\" — Decide would never appear.")
    }
    return problems
  }
}
