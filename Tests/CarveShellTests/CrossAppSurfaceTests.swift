// Tests/CarveShellTests/CrossAppSurfaceTests.swift
// Why: Instagram/Snapchat/Maps evidence must appear in the right apps only after
// the discovery path that case JSON declares — not because of fragment ids.

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

struct CrossAppSurfaceTests {
  @Test func socialAndMapsContentRouteBySurfaceNotId() throws {
    let session = GameSession(caseFile: try loadFiveMinutes())
    #expect(session.visibleFragments(in: .photoSocial).isEmpty)
    #expect(session.visibleFragments(in: .ephemeralChat).isEmpty)
    #expect(session.visibleFragments(in: .places).isEmpty)

    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)

    // Instagram profile unlocks from Messages Sable — still not in Messages list.
    #expect(session.isVisible("ig_sable_profile"))
    #expect(session.visibleFragments(in: .photoSocial).contains { $0.id == "ig_sable_profile" })
    #expect(session.visibleFragments(in: .messages).contains { $0.id == "ig_sable_profile" } == false)

    #expect(session.openFragment("ig_sable_profile").outcome == .ok)
    #expect(session.openFragment("ig_post_thursday").outcome == .ok)
    #expect(session.openFragment("ig_dm_sable").outcome == .ok)

    #expect(session.isVisible("snap_sable"))
    #expect(session.visibleFragments(in: .ephemeralChat).contains { $0.id == "snap_sable" })
    #expect(session.visibleFragments(in: .messages).contains { $0.id == "snap_sable" } == false)

    session.link("eli", "sable")
    #expect(session.isVisible("record_places"))
    #expect(session.visibleFragments(in: .places).contains { $0.id == "record_places" })

    let places = try #require(session.caseFile.fragments["record_places"])
    let timeline = try FragmentContent.locationTimeline(places)
    #expect(timeline.visits.contains { $0.label.contains("River Court") })

    let snap = try #require(session.caseFile.fragments["snap_sable"])
    let thread = try FragmentContent.thread(snap)
    #expect(thread.streakDays == 47)
    #expect(thread.messages.contains { $0.state == "screenshot" })
  }
}
