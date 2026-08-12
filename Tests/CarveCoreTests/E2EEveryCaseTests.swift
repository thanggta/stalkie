// Tests/CarveCoreTests/E2EEveryCaseTests.swift
// Why: a new case must file a complete verdict and have load-bearing
// linked / compound gates without a case-id branch in Swift.

import Foundation
import Testing
@testable import CarveCore

struct E2EEveryCaseTests {
  @Test func everyCaseUnderCasesCanFileItsAnswerKey() throws {
    let cases = try loadAllCases()
    #expect(!cases.isEmpty)

    for c in cases {
      let answers = Dictionary(uniqueKeysWithValues: c.questions.map { ($0.id, $0.correct) })
      let result = fileVerdict(c, answers)
      guard case .filed(let report) = result else {
        Issue.record("case \(c.id): expected filed verdict, got \(result)")
        continue
      }
      #expect(report.total == c.questions.count, "case \(c.id) filed total")
      #expect(report.correct == c.questions.count, "case \(c.id) answer key must score clean")
    }
  }

  @Test func everyLinkedGateIsLoadBearing() throws {
    let cases = try loadAllCases()
    var casesWithLinked = 0

    for c in cases {
      let linkedFragments = c.fragments.values.filter { fragment in
        guard let raw = fragment.hiddenUntil else { return false }
        return jsonContainsKey(raw, key: "linked")
      }
      if linkedFragments.isEmpty { continue }
      casesWithLinked += 1

      for fragment in linkedFragments {
        var engine = CarveEngine(caseFile: c)
        // Carve everything currently visible without drawing links.
        carveAllCurrentlyVisible(&engine)
        let closedMessage = "case " + c.id + ": " + fragment.id + " must stay closed until the link is drawn"
        #expect(engine.isVisible(fragment.id) == false, Comment(rawValue: closedMessage))

        if let raw = fragment.hiddenUntil {
          for pair in linkedPairs(in: raw) {
            engine.link(pair.0, pair.1)
          }
        }
        carveAllCurrentlyVisible(&engine)
        let openedMessage = "case " + c.id + ": drawing the declared link must open " + fragment.id
        #expect(engine.isVisible(fragment.id), Comment(rawValue: openedMessage))
      }
    }

    #expect(casesWithLinked >= 1, "at least one case must use a linked gate")
  }
}

private func loadAllCases() throws -> [CaseFile] {
  let casesDir = "cases"
  guard let entries = try? FileManager.default.contentsOfDirectory(atPath: casesDir) else {
    throw CaseFormatError("cases/ directory not found — run `swift test` from the package root")
  }
  return try entries.sorted().compactMap { name in
    let dir = "\(casesDir)/\(name)"
    guard FileManager.default.fileExists(atPath: "\(dir)/case.json") else { return nil }
    return try loadCase(at: dir)
  }
}

private func loadCase(at dir: String) throws -> CaseFile {
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found in \(dir)")
  var fragmentFiles: [(name: String, data: Data)] = []
  let fragmentsDir = "\(dir)/fragments"
  let names = try FileManager.default.contentsOfDirectory(atPath: fragmentsDir)
  for name in names.sorted() where name.hasSuffix(".json") {
    if let data = FileManager.default.contents(atPath: "\(fragmentsDir)/\(name)") {
      fragmentFiles.append((name: name, data: data))
    }
  }
  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}

private func carveAllCurrentlyVisible(_ engine: inout CarveEngine) {
  var progress = true
  while progress {
    progress = false
    for id in engine.caseFile.fragments.keys.sorted() {
      if engine.canCarve(id) {
        _ = engine.carve(id)
        progress = true
      }
    }
  }
}

private func jsonContainsKey(_ object: [String: JSONValue], key: String) -> Bool {
  if object[key] != nil { return true }
  return object.values.contains { jsonContainsKey($0, key: key) }
}

private func jsonContainsKey(_ value: JSONValue, key: String) -> Bool {
  switch value {
  case .object(let obj):
    return jsonContainsKey(obj, key: key)
  case .array(let arr):
    return arr.contains { jsonContainsKey($0, key: key) }
  default:
    return false
  }
}

private func linkedPairs(in object: [String: JSONValue]) -> [(String, String)] {
  var pairs: [(String, String)] = []
  if case .array(let ids) = object["linked"] {
    let names = ids.compactMap { value -> String? in
      if case .string(let s) = value { return s }
      return nil
    }
    if names.count == 2 {
      pairs.append((names[0], names[1]))
    }
  }
  for value in object.values {
    pairs.append(contentsOf: linkedPairs(in: value))
  }
  return pairs
}

private func linkedPairs(in value: JSONValue) -> [(String, String)] {
  switch value {
  case .object(let obj):
    return linkedPairs(in: obj)
  case .array(let arr):
    return arr.flatMap(linkedPairs)
  default:
    return []
  }
}
