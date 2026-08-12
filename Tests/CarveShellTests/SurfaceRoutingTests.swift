// Tests/CarveShellTests/SurfaceRoutingTests.swift
// Why: home-screen apps must host fragments by declarative surface, never by id.

import Foundation
import Testing
@testable import CarveCore
@testable import CarveShell

struct SurfaceRoutingTests {
  @Test func hostingMapsSurfacesToAppsWithoutBrandStrings() {
    #expect(PhoneAppId.hosting(surface: .messages) == .messages)
    #expect(PhoneAppId.hosting(surface: .maps) == .places)
    #expect(PhoneAppId.hosting(surface: .photoSocial) == .photoSocial)
    #expect(PhoneAppId.hosting(surface: .ephemeralChat) == .ephemeralChat)
  }

  @Test func brandLabelsLiveOnlyInPhoneAppLabels() {
    #expect(PhoneAppLabels.title(for: .places) == "Google Maps")
    #expect(PhoneAppLabels.title(for: .photoSocial) == "Instagram")
    #expect(PhoneAppLabels.title(for: .ephemeralChat) == "Snapchat")
    // Retreat path: inventing names is a config edit in PhoneAppLabels only.
    #expect(PhoneAppId.places.rawValue != "Google Maps")
    #expect(PhoneAppId.photoSocial.rawValue == "photo_social")
  }

  @Test func fragmentSurfaceRoutesIntoCorrectAppList() throws {
    let fragment = Fragment(
      id: "ig_dm",
      type: .thread,
      label: "DM",
      damage: DamageSpec(profile: "block-loss", intensity: 0.1, seed: 1),
      surface: .photoSocial,
      content: [
        "participants": .array([
          .object(["entityId": .string("eli"), "display": .string("Eli")]),
          .object(["entityId": .string("sable"), "display": .string("Sable")]),
        ]),
        "messages": .array([
          .object([
            "at": .string("2026-01-01T00:00:00Z"),
            "from": .string("sable"),
            "text": .string("hi"),
            "corrupt": .bool(false),
          ])
        ]),
      ])
    let caseFile = CaseFile(
      schemaVersion: 1,
      id: "t",
      title: "t",
      sectorMap: [
        SectorEntry(fragmentId: "ig_dm", typeHint: .thread, integrity: 1)
      ],
      questions: [
        VerdictQuestion(
          id: "q1", prompt: "p", options: ["a"], correct: "a", supportedBy: ["ig_dm"])
      ],
      fragments: ["ig_dm": fragment])

    let session = GameSession(caseFile: caseFile)
    #expect(session.visibleFragments(in: .photoSocial).contains { $0.id == "ig_dm" })
    #expect(session.visibleFragments(in: .messages).isEmpty)
    #expect(PhoneAppId.hosting(fragment: fragment) == .photoSocial)
  }
}
