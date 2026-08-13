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

  @Test func drawingLinkProducesCanonicalKeyAndUnlocksGatedFragment() throws {
    // Wiring, not rules: session.link must store the engine's canonical key and
    // surface fragments gated on `linked`. Break linkKey and this fails.
    let session = GameSession(caseFile: try loadFiveMinutes())

    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)
    #expect(session.isVisible("record_places") == false)
    #expect(session.linkedPairs.isEmpty)

    session.link("sable", "eli")

    #expect(session.linkedPairs == ["eli|sable"])
    #expect(session.hasLink("eli", "sable"))
    #expect(session.hasLink("sable", "eli"))
    #expect(session.isVisible("record_places"))
    #expect(session.pendingNotices.contains { $0.fragmentId == "record_places" })

    // Board entities come from carved content — no separate entity table.
    let ids = Set(session.boardEntities.map(\.entityId))
    #expect(ids.contains("eli"))
    #expect(ids.contains("sable"))
  }

  @Test func linkBoardCanonicalSelfAndDuplicatePrevention() throws {
    let session = GameSession(caseFile: try loadFiveMinutes())
    #expect(session.openFragment("thread_theo").outcome == .ok)
    #expect(session.openFragment("thread_sable").outcome == .ok)

    // Re-linking same pair is idempotent
    session.link("sable", "eli")
    session.link("eli", "sable")
    #expect(session.linkedPairs == ["eli|sable"])

    // Self-link is impossible / ignored
    session.link("eli", "eli")
    #expect(session.linkedPairs == ["eli|sable"])
  }

  @Test func unansweredQuestionCountsWrongThroughSessionPath() throws {
    // fileVerdict refuses incomplete sets; scoreVerdict through draftAnswers
    // still counts blanks as wrong — the UI must not invent a free pass.
    let session = GameSession(caseFile: try loadFiveMinutes())
    let correct: [String: String] = [
      "q_sable_who": "affair",
      "q_thursday_lie": "yes",
      "q_thursday_where": "with_sable",
      "q_theo_cover": "yes",
      "q_theo_knew": "unknown",
      "q_usual_place": "sable_place",
      "q_rae_mentioned": "yes",
      "q_hide_phone": "yes",
      "q_ivy_party": "no",
      "q_ivy_knows_affair": "unknown",
      "q_how_long": "weeks",
      "q_unsent_to": "sable",
      "q_still_active": "yes",
      "q_mom_related": "no",
      "q_leaving": "unknown",
    ]

    for (id, option) in correct where id != "q_leaving" {
      session.setAnswer(questionId: id, option: option)
    }

    #expect(session.engine.state.answeredQuestionIds.contains("q_sable_who"))
    #expect(session.engine.state.answeredQuestionIds.contains("q_leaving") == false)

    let incomplete = session.fileVerdict()
    guard case .incomplete(let missing) = incomplete else {
      Issue.record("expected incomplete filing, got \(incomplete)")
      return
    }
    #expect(missing == ["q_leaving"])
    #expect(session.isFiled == false)

    // Direct scoring of the same draft the UI holds: blank is wrong, not omitted.
    let report = scoreVerdict(session.caseFile, session.draftAnswers)
    #expect(report.total == 15)
    #expect(report.results.first { $0.questionId == "q_leaving" }?.isCorrect == false)

    session.setAnswer(questionId: "q_leaving", option: "yes")  // wrong on purpose
    let filed = session.fileVerdict()
    guard case .filed(let finalReport) = filed else {
      Issue.record("expected filed, got \(filed)")
      return
    }
    #expect(session.isFiled)
    #expect(finalReport.results.first { $0.questionId == "q_leaving" }?.isCorrect == false)
    #expect(finalReport.correct == 14)
  }
}
