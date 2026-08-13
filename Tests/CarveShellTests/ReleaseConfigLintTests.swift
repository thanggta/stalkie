// Tests/CarveShellTests/ReleaseConfigLintTests.swift
// Why: release blockers hide in project config. Catch them before ASC upload.

import Foundation
import Testing

struct ReleaseConfigLintTests {
  @Test func infoPlistDeclaresExportComplianceExemption() throws {
    let url = try #require(repoFile("Apps/Carve/Info.plist"))
    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(
      text.contains("ITSAppUsesNonExemptEncryption"),
      "Missing ITSAppUsesNonExemptEncryption — App Store Connect will re-prompt every upload")
    // Key must be false (exempt / no custom crypto) for this local-only game.
    let pattern = #"ITSAppUsesNonExemptEncryption</key>\s*<false/>"#
    #expect(
      text.range(of: pattern, options: .regularExpression) != nil,
      "ITSAppUsesNonExemptEncryption must be false for HTTPS-only system APIs")
  }

  @Test func appTargetOptsOutOfMacAndVisionDesignedForIphone() throws {
    let url = try #require(repoFile("Apps/Carve.xcodeproj/project.pbxproj"))
    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(text.contains("SUPPORTS_MAC_DESIGNED_FOR_IPHONE = NO"))
    #expect(text.contains("SUPPORTS_XR_DESIGNED_FOR_IPHONE = NO"))
    #expect(text.contains("SUPPORTS_MACCATALYST = NO"))
    #expect(text.contains("TARGETED_DEVICE_FAMILY = 1"))
    #expect(text.contains("SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\""))
  }

  @Test func productIdsLiveOnlyInCatalogNotInUISources() throws {
    // Why: DR catalog centralization — views must not hardcode StoreKit product IDs.
    let uiRoot = try #require(repoFile("Sources/CarveUI"))
    var hits: [String] = []
    try scanSwift(uiRoot) { path, line, number in
      if line.contains("games.carve.case.") {
        hits.append("\(path):\(number): \(line.trimmingCharacters(in: .whitespaces))")
      }
    }
    #expect(
      hits.isEmpty,
      "Product IDs must come from catalog.json only:\n\(hits.joined(separator: "\n"))")
  }

  @Test func noPrivacyUsageDescriptionsForUnusedDeviceData() throws {
    let url = try #require(repoFile("Apps/Carve/Info.plist"))
    let text = try String(contentsOf: url, encoding: .utf8)
    let forbidden = [
      "NSPhotoLibraryUsageDescription",
      "NSContactsUsageDescription",
      "NSLocationWhenInUseUsageDescription",
      "NSLocationAlwaysAndWhenInUseUsageDescription",
      "NSCameraUsageDescription",
      "NSMicrophoneUsageDescription",
      "NSFaceIDUsageDescription",
    ]
    for key in forbidden {
      #expect(
        !text.contains(key),
        "Unused permission \(key) must not appear — compliance §7 / §8")
    }
  }
}

private func repoFile(_ relative: String) -> URL? {
  var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  for _ in 0..<8 {
    let candidate = dir.appendingPathComponent(relative)
    if FileManager.default.fileExists(atPath: candidate.path) {
      return candidate
    }
    dir = dir.deletingLastPathComponent()
  }
  let local = URL(fileURLWithPath: relative)
  return FileManager.default.fileExists(atPath: local.path) ? local : nil
}

private func scanSwift(_ root: URL, visit: (String, String, Int) throws -> Void) throws {
  let fm = FileManager.default
  guard let enumerator = fm.enumerator(
    at: root,
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles])
  else { return }

  while let url = enumerator.nextObject() as? URL {
    guard url.pathExtension == "swift" else { continue }
    let text = try String(contentsOf: url, encoding: .utf8)
    for (i, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
      try visit(url.lastPathComponent, String(line), i + 1)
    }
  }
}
