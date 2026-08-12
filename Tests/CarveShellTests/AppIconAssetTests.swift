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

  @Test func iosAppIconIsARealNonPlaceholderPNG() throws {
    // Archive/review uses the 1024 marketing slot. A missing or 1x1 placeholder
    // would ship as the generic white iOS icon.
    let url = try #require(iosAppIconURL(), "AppIcon.appiconset/AppIcon.png is missing")
    let data = try Data(contentsOf: url)
    #expect(data.count > 40_000, "AppIcon.png is too small to be a real 1024 icon (\(data.count) bytes)")
    let bytes = [UInt8](data.prefix(8))
    #expect(bytes == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    // IHDR width/height must be 1024 — not a stub.
    #expect(data.count > 24)
    let width = u32be(data, offset: 16)
    let height = u32be(data, offset: 20)
    #expect(width == 1024)
    #expect(height == 1024)

    let contents = url.deletingLastPathComponent().appendingPathComponent("Contents.json")
    let json = try String(contentsOf: contents, encoding: .utf8)
    #expect(json.contains("AppIcon.png"))
    #expect(json.contains("1024x1024"))
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

  private func iosAppIconURL() -> URL? {
    var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    for _ in 0..<8 {
      let url = dir.appendingPathComponent(
        "Apps/Carve/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
      if FileManager.default.fileExists(atPath: url.path) {
        return url
      }
      dir = dir.deletingLastPathComponent()
    }
    let local = URL(fileURLWithPath: "Apps/Carve/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    if FileManager.default.fileExists(atPath: local.path) { return local }
    return nil
  }

  private func u32be(_ data: Data, offset: Int) -> UInt32 {
    let slice = data[offset..<(offset + 4)]
    return slice.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
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
