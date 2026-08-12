// Tests/CarveShellTests/OwnerEntityTests.swift
// Why: a second case cannot use a different phone owner if the shell
// hardcodes "eli". That is character-name routing — the schema failed.

import Foundation
import Testing
@testable import CarveCore
@testable import CarveShell

struct OwnerEntityTests {
  @Test func threadCounterpartyIsNotHardcodedToEli() throws {
    let fragment = try threadFragment(
      owner: "jonah",
      other: "mara",
      otherDisplay: "Mara")
    let content = try FragmentContent.thread(fragment)

    #expect(content.counterpartyDisplay(ownerEntityId: "jonah") == "Mara")
    #expect(content.isFromOwner("jonah", ownerEntityId: "jonah"))
    #expect(content.isFromOwner("mara", ownerEntityId: "jonah") == false)
    // The eli fallback must not steal the counterparty when the owner is someone else.
    #expect(content.counterpartyDisplay(ownerEntityId: "jonah") != "Jonah")
  }

  @Test func parserReadsOwnerEntityId() throws {
    let manifest = """
      {
        "schemaVersion": 1,
        "id": "owner_probe",
        "title": "Owner Probe",
        "ownerEntityId": "jonah",
        "sectorMap": [
          { "fragmentId": "t1", "typeHint": "thread", "integrity": 1 }
        ],
        "verdict": { "questions": [] }
      }
      """.data(using: .utf8)!
    let fragment = """
      {
        "id": "t1",
        "type": "thread",
        "label": "Mara",
        "damage": { "profile": "block-loss", "intensity": 0.1, "seed": 1 },
        "content": {
          "participants": [
            { "entityId": "jonah", "display": "Jonah" },
            { "entityId": "mara", "display": "Mara" }
          ],
          "messages": [
            { "at": "2026-01-01T00:00:00Z", "from": "jonah", "text": "hey", "corrupt": false }
          ]
        }
      }
      """.data(using: .utf8)!
    let parsed = try parseCase(manifestData: manifest, fragmentFiles: [("t1.json", fragment)])
    #expect(parsed.ownerEntityId == "jonah")
  }
}

private func threadFragment(owner: String, other: String, otherDisplay: String) throws -> Fragment {
  Fragment(
    id: "t",
    type: .thread,
    label: otherDisplay,
    damage: DamageSpec(profile: "block-loss", intensity: 0.1, seed: 1),
    content: [
      "participants": .array([
        .object(["entityId": .string(owner), "display": .string(owner.capitalized)]),
        .object(["entityId": .string(other), "display": .string(otherDisplay)]),
      ]),
      "messages": .array([
        .object([
          "at": .string("2026-01-01T00:00:00Z"),
          "from": .string(owner),
          "text": .string("hey"),
          "corrupt": .bool(false),
        ])
      ]),
    ])
}
