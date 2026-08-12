// Tests/CarveCoreTests/StrictJSONTests.swift
import Foundation
import Testing
@testable import CarveCore

struct StrictJSONTests {
  private func data(_ json: String) -> Data { Data(json.utf8) }

  @Test func acceptsWellFormedJSON() throws {
    try validateStrictJSON(data(#"{"a": 1, "b": [1, 2, 3], "c": {"d": null, "e": true}}"#))
  }

  @Test func acceptsNestedArraysAndObjectsWithWhitespace() throws {
    try validateStrictJSON(data("""
      {
        "sectorMap": [ { "fragmentId": "a", "integrity": 0.9 },
                       { "fragmentId": "b", "integrity": 0.4 } ]
      }
      """))
  }

  @Test func rejectsTrailingCommaInObject() {
    // Rule 9a: this is the exact defect Foundation's JSONDecoder tolerates, so
    // "parses fine" proves nothing — the strict check must be the gate.
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{"a": 1,}"#))
    }
    do {
      try validateStrictJSON(data(#"{"a": 1,}"#))
      Issue.record("expected StrictJSONError")
    } catch let error as StrictJSONError {
      guard case .trailingCommaAt = error else {
        Issue.record("expected trailingCommaAt, got \(error)")
        return
      }
    } catch {
      Issue.record("expected StrictJSONError, got \(error)")
    }
  }

  @Test func rejectsTrailingCommaInArray() {
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"[1, 2, 3,]"#))
    }
  }

  @Test func rejectsTrailingCommaInNestedContainer() {
    // The lenient decoder also ships this; the check must find it at depth.
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{"a": {"b": [1, 2],}, "c": [3, 4]}"#))
    }
  }

  @Test func rejectsDuplicateObjectKey() {
    // Two "id" keys is an authoring error: the decoder keeps one arbitrarily.
    do {
      try validateStrictJSON(data(#"{"id": "a", "id": "b"}"#))
      Issue.record("expected StrictJSONError")
    } catch let error as StrictJSONError {
      guard case .duplicateKeyAt(_, let key) = error else {
        Issue.record("expected duplicateKeyAt, got \(error)")
        return
      }
      #expect(key == "id")
    } catch {
      Issue.record("expected StrictJSONError, got \(error)")
    }
  }

  @Test func duplicateKeysAreDetectedInsideNestedContent() {
    // content is free-form JSON, so the check must recurse through it.
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{"content": {"rows": [{"a": 1, "a": 2}]}}"#))
    }
  }

  @Test func acceptsEscapedQuotesAndEscapedCharacters() throws {
    try validateStrictJSON(data(#"{"a": "say \"hi\" \n \\ \u0041", "b": "✓"}"#))
  }

  @Test func acceptsNumbersInEveryForm() throws {
    try validateStrictJSON(data(#"{"a": -12, "b": 3.14, "c": 1e10, "d": -2.5e-3, "e": 0, "f": 0.5}"#))
  }

  @Test func rejectsGarbageAfterValue() {
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{"a": 1} extra"#))
    }
  }

  @Test func rejectsUnterminatedObject() {
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{"a": 1"#))
    }
  }

  @Test func rejectsUnquotedObjectKey() {
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(data(#"{a: 1}"#))
    }
  }

  @Test func emptyArrayAndEmptyObjectAreValid() throws {
    try validateStrictJSON(data(#"[]"#))
    try validateStrictJSON(data(#"{}"#))
  }

  @Test func nonUTF8DataIsRejected() {
    let invalid = Data([0xFF, 0xFE, 0xFD])
    #expect(throws: StrictJSONError.self) {
      try validateStrictJSON(invalid)
    }
  }
}
