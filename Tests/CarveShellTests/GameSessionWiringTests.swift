// Tests/CarveShellTests/GameSessionWiringTests.swift
// Wiring, not rules: opening carves; gated fragments appear after predicates.
// If this passes while DR-11 is broken in the shell path, the shell is lying.

import Foundation
import Testing
@testable import CarveCore
@testable import CarveShell

private func loadFiveMinutes() throws -> CaseFile {
  let dir = "cases/five_minutes"
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found — run `swift test` from the package root")
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

struct GameSessionWiringTests {
  @Test func openingFragmentCarvesIt() throws {
    let session = GameSession(caseFile: try loadFiveMinutes())
    #expect(session.engine.carvedIds.contains("thread_theo") == false)

    let result = session.openFragment("thread_theo")
    #expect(result.outcome == .ok)
    #expect(session.engine.carvedIds.contains("thread_theo"))
    #expect(session.openedIds.contains("thread_theo"))
  }

  @Test func gatedFragmentAbsentBeforePredicateThenPresentAfter() throws {
    let session = GameSession(caseFile: try loadFiveMinutes())

    // Before: Sable thread must not appear in any app list.
    #expect(session.isVisible("thread_sable") == false)
    #expect(session.visibleFragments(in: .messages).contains { $0.id == "thread_sable" } == false)
    #expect(session.openFragment("thread_sable").outcome == .hidden)

    // After carving the gate: it appears, is unread, and a notice is pending.
    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.isVisible("thread_sable"))
    #expect(session.visibleFragments(in: .messages).contains { $0.id == "thread_sable" })
    #expect(session.unreadUnlockIds.contains("thread_sable"))
    #expect(session.pendingNotices.contains { $0.fragmentId == "thread_sable" })
    #expect(session.badgeCount(for: .messages) >= 1)

    // Opening the unlock clears unread for that fragment.
    #expect(session.openFragment("thread_sable").outcome == .ok)
    #expect(session.unreadUnlockIds.contains("thread_sable") == false)
  }

  @Test func imageFragmentsUnlockThroughDiscovery() throws {
    let session = GameSession(caseFile: try loadFiveMinutes())
    let images = session.caseFile.fragments.values.filter { $0.type == .image }
    #expect(images.count >= 2, "case must ship image fragments so Photos + damage fire in play")

    let gatedImages = images.filter { $0.hiddenUntil != nil }
    #expect(gatedImages.isEmpty == false, "at least one image must be gated")

    for image in gatedImages {
      #expect(session.isVisible(image.id) == false)
    }

    // Walk a path that opens photos: theo → sable → jacket photo, etc.
    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)

    let nowVisible = gatedImages.filter { session.isVisible($0.id) }
    #expect(
      nowVisible.isEmpty == false,
      "carving the gate path must surface at least one gated image")
  }

  @Test func bothThemesAreDistinctAndSelectable() {
    let a = Theme.iosLookalike
    let b = Theme.fallbackWorkstation
    #expect(a.id != b.id)
    #expect(a.radii.appIcon != b.radii.appIcon)
    #expect(a.icon.kind != b.icon.kind)
    #expect(a.fonts.family != b.fonts.family || a.palette.screenBackground != b.palette.screenBackground)

    let session = GameSession(
      caseFile: CaseFile(
        schemaVersion: 1,
        id: "t",
        title: "t",
        sectorMap: [],
        questions: [],
        fragments: [:]),
      themeId: a.id)
    #expect(session.theme.id == a.id)
    session.setTheme(b.id)
    #expect(session.theme.id == b.id)
  }
}
