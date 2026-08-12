// Tests/CarveShellTests/ThemeLiteralLintTests.swift
// Fails if a view body invents radii, fonts, or colors instead of reading Theme.
// Source scan is intentional: it is the check that keeps DR-8's retreat plan real.

import Foundation
import Testing

struct ThemeLiteralLintTests {
  @Test func appViewsContainNoHardcodedVisualLiterals() throws {
    let roots = try viewSourceRoots()
    #expect(roots.isEmpty == false, "expected Apps/Carve view sources on disk")

    var violations: [String] = []
    for root in roots {
      try scanDirectory(root, violations: &violations)
    }

    #expect(
      violations.isEmpty,
      """
      View bodies must read Theme — no literal radii/fonts/colors.
      \(violations.joined(separator: "\n"))
      """)
  }

  @Test func twoBuiltInThemesExist() {
    #expect(Theme.allBuiltIn.count >= 2)
    #expect(Set(Theme.allBuiltIn.map(\.id)).count >= 2)
  }
}

// Import Theme via CarveShell for the second test.
import CarveShell

// MARK: - Scanner

private func viewSourceRoots() throws -> [URL] {
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

private func scanDirectory(_ root: URL, violations: inout [String]) throws {
  let fm = FileManager.default
  guard let enumerator = fm.enumerator(
    at: root,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles])
  else { return }

  // Theme definition files and Color bridging may use literals; views must not.
  let allowNameSubstrings = [
    "Theme",
    "ThemeColor+",
    "Color+Theme",
    "Preview",
  ]

  while let url = enumerator.nextObject() as? URL {
    guard url.pathExtension == "swift" else { continue }
    let name = url.lastPathComponent
    if allowNameSubstrings.contains(where: { name.contains($0) }) { continue }

    let text = try String(contentsOf: url, encoding: .utf8)
    let relative = url.path.replacingOccurrences(
      of: root.deletingLastPathComponent().deletingLastPathComponent().path + "/",
      with: "")

    for (lineNumber, line) in text.split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("//") { continue }
      if let reason = literalViolation(in: String(line)) {
        violations.append("\(relative):\(lineNumber + 1): \(reason) — \(trimmed)")
      }
    }
  }
}

private func literalViolation(in line: String) -> String? {
  // Corner / continuous radii with numeric literals.
  let radiusPatterns = [
    #"\.cornerRadius\(\s*\d+"#,
    #"RoundedRectangle\(cornerRadius:\s*\d+"#,
    #"UnevenRoundedRectangle"#,
    #"\.clipShape\(\s*RoundedRectangle\(cornerRadius:\s*\d+"#,
  ]
  for pattern in radiusPatterns {
    if line.range(of: pattern, options: .regularExpression) != nil {
      return "hardcoded radius"
    }
  }

  // Font face / system style literals in view code.
  let fontPatterns = [
    #"\.font\(\s*\.system"#,
    #"\.font\(\s*\.body"#,
    #"\.font\(\s*\.headline"#,
    #"\.font\(\s*\.title"#,
    #"\.font\(\s*\.caption"#,
    #"\.font\(\s*\.footnote"#,
    #"Font\.custom\(\s*\""#,
    #"Font\.system\("#,
  ]
  for pattern in fontPatterns {
    if line.range(of: pattern, options: .regularExpression) != nil {
      return "hardcoded font"
    }
  }

  // Color literals — Color.red, Color(red:, .white, UIColor, hex-ish.
  let colorPatterns = [
    #"\bColor\.(red|blue|green|white|black|gray|orange|yellow|pink|purple|primary|secondary|accentColor)\b"#,
    #"\bColor\(\s*red:"#,
    #"\bColor\(\s*\.\w+"#,
    #"\bUIColor\b"#,
    #"#colorLiteral"#,
    #"\.foregroundStyle\(\s*\.(red|blue|green|white|black|gray|primary|secondary)"#,
    #"\.foregroundColor\(\s*\.(red|blue|green|white|black|gray|primary|secondary)"#,
    #"\.background\(\s*\.(red|blue|green|white|black|gray|ultraThinMaterial)"#,
    #"\.tint\(\s*\.(red|blue|green|white|black|gray)"#,
    #"\.fill\(\s*\.(red|blue|green|white|black|gray)"#,
    #"\.stroke\(\s*\.(red|blue|green|white|black|gray)"#,
  ]
  for pattern in colorPatterns {
    if line.range(of: pattern, options: .regularExpression) != nil {
      return "hardcoded color"
    }
  }

  return nil
}
