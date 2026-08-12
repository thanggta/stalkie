// Tests/CarveShellTests/ImageAccessibilityTests.swift
// Why: VoiceOver must describe evidence without spoiling `depicts`.

import Foundation
import Testing
import CarveCore
@testable import CarveShell

struct ImageAccessibilityTests {
  @Test func shippedImagesHaveNonSpoilerDescriptions() throws {
    for id in ["five_minutes", "dont_wait_up"] {
      let caseFile = try loadCase(id)
      let images = caseFile.fragments.values.filter { $0.type == .image }
      #expect(!images.isEmpty)
      for fragment in images {
        let content = try FragmentContent.image(fragment)
        let description = content.accessibilityDescription
        #expect(
          description != nil && !(description ?? "").isEmpty,
          "\(id)/\(fragment.id) needs accessibilityDescription")
        for depicted in content.depicts {
          #expect(
            !(description ?? "").localizedCaseInsensitiveContains(depicted),
            "\(fragment.id) accessibilityDescription must not leak depicts \(depicted)")
        }
      }
    }
  }
}

private func loadCase(_ id: String) throws -> CaseFile {
  let dir = "cases/\(id)"
  let manifestData = try #require(FileManager.default.contents(atPath: "\(dir)/case.json"))
  var fragmentFiles: [(name: String, data: Data)] = []
  let names = try FileManager.default.contentsOfDirectory(atPath: "\(dir)/fragments")
  for name in names.sorted() where name.hasSuffix(".json") {
    if let data = FileManager.default.contents(atPath: "\(dir)/fragments/\(name)") {
      fragmentFiles.append((name: name, data: data))
    }
  }
  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}
