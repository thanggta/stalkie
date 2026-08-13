// Tests/CarveShellTests/PlayerFacingCopyTests.swift
// Why: the player is in a relationship drama, not an engine. Production copy
// that leaks fragment/carve/schema language breaks the fantasy.

import Foundation
import Testing
@testable import CarveShell

struct PlayerFacingCopyTests {
  @Test func productionCopyHasNoEngineVocabulary() {
    let strings = [
      PlayerFacingCopy.saveFailed,
      PlayerFacingCopy.saveFailedRetry,
      PlayerFacingCopy.loadFailedTitle,
      PlayerFacingCopy.loadFailedBody,
      PlayerFacingCopy.imageMissing,
      PlayerFacingCopy.imageRecovering,
    ]
    for text in strings {
      #expect(
        PlayerFacingCopy.containsEngineVocabulary(text) == false,
        "player copy leaked engine vocabulary: \(text)")
    }
  }

  @Test func verdictOptionLabelMatchesVisibleTitleCase() {
    // Why: VoiceOver must speak the same words the sighted player sees.
    // A raw snake_case option id is not a label.
    #expect(PlayerFacingCopy.verdictOptionLabel("party_help") == "Party Help")
    #expect(PlayerFacingCopy.verdictOptionLabel("yes") == "Yes")
    #expect(PlayerFacingCopy.verdictOptionLabel("sable_place") == "Sable Place")
    #expect(PlayerFacingCopy.verdictOptionLabel("") == "(nothing)")
  }

  @Test func uiSourceStringLiteralsDoNotUseEngineVocabulary() throws {
    let roots = try uiSourceRoots()
    #expect(!roots.isEmpty)

    let forbidden = PlayerFacingCopy.engineVocabulary
    var hits: [String] = []

    for root in roots {
      try scan(root, forbidden: forbidden, hits: &hits)
    }

    #expect(
      hits.isEmpty,
      """
      Player-facing string literals must not use engine vocabulary.
      \(hits.joined(separator: "\n"))
      """)
  }
}

private func uiSourceRoots() throws -> [URL] {
  var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  for _ in 0..<6 {
    let ui = dir.appendingPathComponent("Sources/CarveUI")
    if FileManager.default.fileExists(atPath: ui.path) {
      return [ui]
    }
    dir = dir.deletingLastPathComponent()
  }
  let local = URL(fileURLWithPath: "Sources/CarveUI")
  if FileManager.default.fileExists(atPath: local.path) { return [local] }
  return []
}

private func scan(_ root: URL, forbidden: [String], hits: inout [String]) throws {
  let fm = FileManager.default
  guard let enumerator = fm.enumerator(
    at: root,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles])
  else { return }

  while let url = enumerator.nextObject() as? URL {
    guard url.pathExtension == "swift" else { continue }
    let text = try String(contentsOf: url, encoding: .utf8)
    let relative = url.lastPathComponent
    for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let raw = String(line)
      let trimmed = raw.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("//") { continue }
      // Only quoted player-facing copy — identifiers like fragmentId are fine.
      let literals = quotedLiterals(in: raw)
      for literal in literals {
        // Bundle ids and accessibility tokens are not player copy.
        guard literal.contains(where: { $0.isWhitespace || $0 == "·" }) else { continue }
        let lower = literal.lowercased()
        for word in forbidden where lower.contains(word) {
          hits.append("\(relative):\(index + 1): \"\(literal)\" contains '\(word)'")
        }
      }
    }
  }
}

private func quotedLiterals(in line: String) -> [String] {
  var result: [String] = []
  var current = ""
  var inString = false
  var escape = false
  for ch in line {
    if inString {
      if escape {
        current.append(ch)
        escape = false
      } else if ch == "\\" {
        escape = true
      } else if ch == "\"" {
        result.append(current)
        current = ""
        inString = false
      } else {
        current.append(ch)
      }
    } else if ch == "\"" {
      inString = true
    }
  }
  return result
}
