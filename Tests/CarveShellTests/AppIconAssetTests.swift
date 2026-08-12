// Tests/CarveShellTests/AppIconAssetTests.swift
// Why: SpringBoard fidelity depends on pre-rendered multi-layer icon faces
// existing on disk for every PhoneAppId. Missing assets fall back to SF stickers
// and the home shell reads as a game lobby again.

import Foundation
import Testing
import CarveShell

struct AppIconAssetTests {
  @Test func everyPhoneAppHasABundledIconMasterOrIsLive() throws {
    let roots = try resourceRoots()
    #expect(!roots.isEmpty)

    let liveDrawn: Set<PhoneAppId> = [.calendar, .clock]
    var missing: [String] = []

    for app in PhoneAppId.allCases {
      if liveDrawn.contains(app) { continue }
      let name = "\(app.rawValue).png"
      let found = roots.contains { root in
        FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path)
      }
      if !found { missing.append(name) }
    }

    #expect(
      missing.isEmpty,
      "Missing AppIcons masters (would render as SF-sticker fallbacks): \(missing.joined(separator: ", "))")
  }

  @Test func dockPhoneMasterIsNonTrivialImage() throws {
    // Handset fidelity: asset must exist and not be an empty/corrupt file.
    let roots = try resourceRoots()
    var data: Data?
    for root in roots {
      let url = root.appendingPathComponent("phone.png")
      if let d = try? Data(contentsOf: url), !d.isEmpty {
        data = d
        break
      }
    }
    #expect(data != nil, "phone.png must ship for dock handset (not share glyph fallback)")
    #expect((data?.count ?? 0) > 2_000, "phone.png looks too small to be a real multi-layer icon")
    // PNG signature
    let bytes = [UInt8](data!.prefix(8))
    #expect(bytes == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
  }

  private func resourceRoots() throws -> [URL] {
    var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    var found: [URL] = []
    for _ in 0..<8 {
      let icons = dir.appendingPathComponent("Sources/CarveUI/Resources/AppIcons")
      if FileManager.default.fileExists(atPath: icons.path) {
        found.append(icons)
      }
      dir = dir.deletingLastPathComponent()
    }
    let local = URL(fileURLWithPath: "Sources/CarveUI/Resources/AppIcons")
    if FileManager.default.fileExists(atPath: local.path) {
      found.append(local)
    }
    return found
  }
}
