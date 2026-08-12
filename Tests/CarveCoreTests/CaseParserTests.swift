import Foundation
import Testing
@testable import CarveCore

struct CaseParserTests {
  private let minimalManifestJSON = """
  { "schemaVersion": 1, "id": "test", "title": "Test Case",
    "sectorMap": [ { "fragmentId": "note_001", "typeHint": "note", "integrity": 0.9 } ],
    "verdict": { "questions": [ { "id": "q1", "prompt": "Who?", "answerType": "entity",
      "options": ["a","b"], "correct": "a", "supportedBy": ["note_001"] } ] } }
  """

  private let minimalFragmentJSON = """
  { "id": "note_001", "type": "note", "label": "A note",
  "damage": { "profile": "block-loss", "intensity": 0.2, "seed": 7 },
  "content": { "title": "x", "body": "y", "modifiedAt": "2026-03-12T02:11:00+07:00" } }
  """

  private func data(_ json: String) -> Data {
    Data(json.utf8)
  }

  private func fragmentFiles(_ jsons: [String: String]) -> [(name: String, data: Data)] {
    jsons.map { (name: $0.key, data: Data($0.value.utf8)) }
  }

  @Test func parsesAWellFormedCase() throws {
    let caseFile = try parseCase(
      manifestData: data(minimalManifestJSON),
      fragmentFiles: fragmentFiles(["note_001.json": minimalFragmentJSON])
    )
    #expect(caseFile.id == "test")
    #expect(caseFile.fragments["note_001"]?.damage.seed == 7)
  }

  @Test func parsesHiddenUntilOnFragment() throws {
    let gated = """
    { "id": "note_002", "type": "note", "label": "Gated",
    "damage": { "profile": "block-loss", "intensity": 0.2, "seed": 9 },
    "hiddenUntil": { "carved": "note_001" },
    "content": { "title": "x", "body": "y" } }
    """
    let manifest = """
    { "schemaVersion": 1, "id": "test", "title": "Test Case",
      "sectorMap": [ { "fragmentId": "note_001", "typeHint": "note", "integrity": 0.9 } ],
      "verdict": { "questions": [ { "id": "q1", "prompt": "Who?", "answerType": "entity",
        "options": ["a","b"], "correct": "a", "supportedBy": ["note_001"] } ] } }
    """
    let caseFile = try parseCase(
      manifestData: data(manifest),
      fragmentFiles: fragmentFiles([
        "note_001.json": minimalFragmentJSON,
        "note_002.json": gated,
      ]))
    #expect(caseFile.fragments["note_002"]?.hiddenUntil != nil)
    guard case .string(let target)? = caseFile.fragments["note_002"]?.hiddenUntil?["carved"] else {
      Issue.record("expected carved predicate")
      return
    }
    #expect(target == "note_001")
  }

  @Test func rejectsUnknownSchemaVersion() {
    let manifest = minimalManifestJSON.replacingOccurrences(
      of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 2")
    expectCaseFormatError(
      manifest: manifest,
      files: fragmentFiles(["note_001.json": minimalFragmentJSON]),
      messageContaining: "Unsupported schemaVersion \"2\"")
  }

  @Test func rejectsFloatSchemaVersion() {
    let manifest = minimalManifestJSON.replacingOccurrences(
      of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 1.0")
    #expect(throws: CaseFormatError.self) {
      try parseCase(manifestData: data(manifest), fragmentFiles: [])
    }
    do {
      _ = try parseCase(manifestData: data(manifest), fragmentFiles: [])
      Issue.record("expected CaseFormatError")
    } catch let error as CaseFormatError {
      #expect(error.message.contains("schemaVersion"))
    } catch {
      Issue.record("expected CaseFormatError, got \(error)")
    }
  }

  @Test func rejectsAudioFragmentWithDRError() {
    let audio = """
    { "id": "audio_001", "type": "audio", "label": "Voicemail",
    "damage": { "profile": "overwrite", "intensity": 0.5, "seed": 3 },
    "content": { "source": "media/vm.m4a", "durationSec": 34 } }
    """
    expectCaseFormatError(
      manifest: minimalManifestJSON,
      files: fragmentFiles([
        "note_001.json": minimalFragmentJSON,
        "audio_001.json": audio,
      ]),
      messageContaining: "DR-6")
  }

  @Test func rejectsFragmentMissingDamageSeed() {
    let noSeed = """
    { "id": "note_001", "type": "note", "label": "A note",
    "damage": { "profile": "block-loss", "intensity": 0.2 },
    "content": { "title": "x", "body": "y" } }
    """
    expectCaseFormatError(
      manifest: minimalManifestJSON,
      files: fragmentFiles(["note_001.json": noSeed]),
      messageContaining: "deterministic")
  }

  @Test func rejectsFragmentNullDamageSeed() {
    // A JSON `null` seed fails Int decoding via valueNotFound, not
    // keyNotFound; both branches must yield the deterministic-damage message.
    let nullSeed = """
    { "id": "note_001", "type": "note", "label": "A note",
    "damage": { "profile": "block-loss", "intensity": 0.2, "seed": null },
    "content": { "title": "x", "body": "y" } }
    """
    expectCaseFormatError(
      manifest: minimalManifestJSON,
      files: fragmentFiles(["note_001.json": nullSeed]),
      messageContaining: "deterministic")
  }

  @Test func rejectsUnknownDamageProfile() {
    let bad = minimalFragmentJSON.replacingOccurrences(of: "block-loss", with: "sparkles")
    #expect(throws: CaseFormatError.self) {
      try parseCase(
        manifestData: data(minimalManifestJSON),
        fragmentFiles: fragmentFiles(["note_001.json": bad]))
    }
  }

  @Test func rejectsAudioTypeHintInSectorMap() {
    let manifest = minimalManifestJSON.replacingOccurrences(
      of: "\"typeHint\": \"note\"", with: "\"typeHint\": \"audio\"")
    expectCaseFormatError(manifest: manifest, files: [], messageContaining: "DR-6")
  }

  @Test func rejectsMalformedManifestJSON() {
    // BLOCKER-2 regression: a manifest Dart's CLI rejects (FormatException) must
    // surface as CaseFormatError, never a crash. Note: Foundation's JSON parser
    // is lenient about trailing commas, so this uses a truncated object instead.
    let truncated = String(minimalManifestJSON.dropLast())
    #expect(throws: CaseFormatError.self) {
      try parseCase(manifestData: data(truncated), fragmentFiles: [])
    }
  }

  @Test func rejectsManifestWithTrailingComma() {
    // Foundation's JSONDecoder tolerates trailing commas, so this used to
    // parse and exit 0. The strict check must reject it before decoding.
    let manifest = """
    { "schemaVersion": 1, "id": "test", "title": "Test Case",
      "sectorMap": [ { "fragmentId": "note_001", "typeHint": "note", "integrity": 0.9 } ],
      "verdict": { "questions": [ { "id": "q1", "prompt": "Who?", "answerType": "entity",
        "options": ["a","b"], "correct": "a", "supportedBy": ["note_001"] } ] }, }
    """
    expectCaseFormatError(
      manifest: manifest,
      files: fragmentFiles(["note_001.json": minimalFragmentJSON]),
      messageContaining: "strict JSON")
  }

  @Test func rejectsFragmentWithTrailingComma() {
    let fragment = """
    { "id": "note_001", "type": "note", "label": "A note",
    "damage": { "profile": "block-loss", "intensity": 0.2, "seed": 7 },
    "content": { "title": "x", "body": "y" }, }
    """
    expectCaseFormatError(
      manifest: minimalManifestJSON,
      files: fragmentFiles(["note_001.json": fragment]),
      messageContaining: "strict JSON")
  }

  @Test func rejectsManifestWithDuplicateKey() {
    let manifest = minimalManifestJSON.replacingOccurrences(
      of: "\"id\": \"test\"", with: "\"id\": \"test\", \"id\": \"test\"")
    expectCaseFormatError(
      manifest: manifest,
      files: fragmentFiles(["note_001.json": minimalFragmentJSON]),
      messageContaining: "duplicate key")
  }

  @Test func rejectsFragmentMissingID() {
    let noID = minimalFragmentJSON.replacingOccurrences(of: "\"id\": \"note_001\", ", with: "")
    #expect(throws: CaseFormatError.self) {
      try parseCase(
        manifestData: data(minimalManifestJSON),
        fragmentFiles: fragmentFiles(["note_001.json": noID]))
    }
  }

  @Test func rejectsManifestMissingVerdict() {
    let noVerdict = """
    { "schemaVersion": 1, "id": "test", "title": "Test Case",
      "sectorMap": [ { "fragmentId": "note_001", "typeHint": "note", "integrity": 0.9 } ] }
    """
    #expect(throws: CaseFormatError.self) {
      try parseCase(manifestData: data(noVerdict), fragmentFiles: [])
    }
  }

  @Test func ignoresLegacyCycleBudgetKey() throws {
    // cycleBudget is gone (DR-11). Extra keys are ignored by Codable; a case
    // must still parse without carveCost on sector entries.
    let withLegacy = """
    { "schemaVersion": 1, "id": "test", "title": "Test Case", "cycleBudget": 99,
      "sectorMap": [ { "fragmentId": "note_001", "typeHint": "note", "integrity": 0.9 } ],
      "verdict": { "questions": [ { "id": "q1", "prompt": "Who?", "answerType": "entity",
        "options": ["a","b"], "correct": "a", "supportedBy": ["note_001"] } ] } }
    """
    let caseFile = try parseCase(
      manifestData: data(withLegacy),
      fragmentFiles: fragmentFiles(["note_001.json": minimalFragmentJSON]))
    #expect(caseFile.id == "test")
  }

  @Test func contentWithNestedJSONSurvivesParsing() throws {
    let nested = """
    { "id": "note_001", "type": "note", "label": "A note",
    "damage": { "profile": "block-loss", "intensity": 0.2, "seed": 7 },
    "content": { "rows": [ { "time": "2026-03-12T02:11:00+07:00", "body": "hello" }, null ],
                 "meta": { "count": 2 } } }
    """
    let caseFile = try parseCase(
      manifestData: data(minimalManifestJSON),
      fragmentFiles: fragmentFiles(["note_001.json": nested])
    )
    let content = caseFile.fragments["note_001"]?.content
    #expect(content != nil)
    guard let content else { return }
    guard case .array(let rows) = content["rows"] else {
      Issue.record("expected content.rows to be an array")
      return
    }
    #expect(rows.count == 2)
    guard case .object(let row) = rows[0], case .string(let body)? = row["body"] else {
      Issue.record("expected first row to be an object with a string body")
      return
    }
    #expect(body == "hello")
    guard case .null = rows[1] else {
      Issue.record("expected second row to be null")
      return
    }
    guard case .object(let meta) = content["meta"], case .number(let count)? = meta["count"] else {
      Issue.record("expected content.meta.count to be a number")
      return
    }
    #expect(count == 2)
  }

  private func expectCaseFormatError(
    manifest: String,
    files: [(name: String, data: Data)],
    messageContaining: String
  ) {
    do {
      _ = try parseCase(manifestData: data(manifest), fragmentFiles: files)
      Issue.record("expected CaseFormatError")
    } catch let error as CaseFormatError {
      #expect(error.message.contains(messageContaining))
    } catch {
      Issue.record("expected CaseFormatError, got \(error)")
    }
  }
}
