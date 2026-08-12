// Tests/CarveCoreTests/E2EFiveMinutesTests.swift
import Foundation
import Testing
@testable import CarveCore

private func loadFiveMinutes() throws -> CaseFile {
  let dir = "cases/five_minutes"
  let manifestData = try #require(
    FileManager.default.contents(atPath: "\(dir)/case.json"),
    "case.json not found — run `swift test` from the package root")

  var fragmentFiles: [(name: String, data: Data)] = []
  let fragmentsDir = "\(dir)/fragments"
  if let names = try? FileManager.default.contentsOfDirectory(atPath: fragmentsDir) {
    for name in names.sorted() where name.hasSuffix(".json") {
      if let data = FileManager.default.contents(atPath: "\(fragmentsDir)/\(name)") {
        fragmentFiles.append((name: name, data: data))
      }
    }
  } else {
    throw CaseFormatError("\(fragmentsDir) not found — run `swift test` from the package root")
  }

  return try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
}

struct E2EFiveMinutesTests {
  @Test func fiveMinutesParsesAndPassesEveryValidatorCheck() throws {
    let c = try loadFiveMinutes()
    let problems = validateCase(c)
    #expect(problems.isEmpty, "validator problems: \(problems)")
  }

  @Test func fiveMinutesUsesDiscoveryGatesNotBudget() throws {
    let c = try loadFiveMinutes()
    #expect(c.questions.count == 15)
    #expect(c.fragments.values.contains { $0.hiddenUntil != nil })

    var engine = CarveEngine(caseFile: c)
    // Gated content stays closed until the player finds the thread that points at it.
    #expect(engine.isVisible("thread_sable") == false)
    #expect(engine.carve("thread_sable").outcome == .hidden)

    #expect(engine.carve("thread_theo").outcome == .ok)
    #expect(engine.isVisible("thread_sable"))
    #expect(engine.carve("thread_sable").outcome == .ok)

    #expect(engine.isVisible("thread_ivy"))
    #expect(engine.isVisible("note_unsent"))
    #expect(engine.isVisible("record_places") == false)

    // Places stay closed until she draws the eli–sable link (not just more carving).
    engine.carve("calls_recent")
    #expect(engine.isVisible("record_places") == false)
    engine.link("sable", "eli")
    #expect(engine.isVisible("record_places"))
    engine.carve("record_places")
    engine.carve("thread_ivy")
    #expect(engine.isVisible("note_calendar"))
    engine.carve("note_calendar")
    engine.carve("note_unsent")
    engine.carve("thread_mom")
    engine.carve("note_lists")
    #expect(engine.isVisible("image_counter"))
    #expect(engine.carve("image_counter").outcome == .ok)
    #expect(engine.isVisible("image_jacket"))
    #expect(engine.carve("image_jacket").outcome == .ok)
  }

  @Test func fiveMinutesPerfectFilingScoresOne() throws {
    let c = try loadFiveMinutes()
    let answers: [String: String] = [
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
    let result = fileVerdict(c, answers)
    guard case .filed(let report) = result else {
      Issue.record("expected filed verdict, got \(result)")
      return
    }
    #expect(report.accuracy == 1.0)
    #expect(report.total == 15)
  }

  @Test func fiveMinutesRefusesIncompleteFiling() throws {
    let c = try loadFiveMinutes()
    let result = fileVerdict(c, ["q_sable_who": "affair"])
    guard case .incomplete(let missing) = result else {
      Issue.record("expected incomplete, got \(result)")
      return
    }
    #expect(missing.count == 14)
  }
}
