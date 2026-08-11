import Foundation
import Testing
@testable import CarveCore

struct JSONValueTests {
  @Test func jsonValueRoundTripsThroughCodable() throws {
    let json = #"{"a":1,"b":[true,null,"x"],"c":{"d":1.5}}"#
    let decoded = try JSONDecoder().decode([String: JSONValue].self, from: Data(json.utf8))
    #expect(decoded["a"] == .number(1.0))
    #expect(decoded["b"] == .array([.bool(true), .null, .string("x")]))
    #expect(decoded["c"] == .object(["d": .number(1.5)]))

    let encoded = try JSONEncoder().encode(decoded)
    let roundTripped = try JSONDecoder().decode([String: JSONValue].self, from: encoded)
    #expect(roundTripped == decoded)
  }

  @Test func jsonValuePreservesNumberKinds() throws {
    let decoded = try JSONDecoder().decode([String: JSONValue].self, from: Data(#"{"a":1}"#.utf8))
    #expect(decoded["a"] == .number(1.0))
  }
}
