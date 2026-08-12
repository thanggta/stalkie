// Tests/CarveCoreTests/ContentSurfaceTests.swift
// Why: app routing must come from declarative surface data, not fragment ids.
// A case author must be able to add Instagram/Snapchat/Maps evidence without Swift.

import Testing
@testable import CarveCore

struct ContentSurfaceTests {
  @Test func defaultsPreserveExistingTypeRouting() {
    #expect(ContentSurface.defaultSurface(for: .thread, recordKind: nil) == .messages)
    #expect(ContentSurface.defaultSurface(for: .note, recordKind: nil) == .notes)
    #expect(ContentSurface.defaultSurface(for: .image, recordKind: nil) == .photos)
    #expect(ContentSurface.defaultSurface(for: .record, recordKind: "location") == .maps)
    #expect(ContentSurface.defaultSurface(for: .record, recordKind: "call_log") == .phone)
  }

  @Test func rejectsUnknownTypeSurfacePairs() {
    #expect(
      ContentSurface.isAllowed(type: .note, surface: .photoSocial, recordKind: nil) == false)
    #expect(
      ContentSurface.isAllowed(type: .thread, surface: .maps, recordKind: nil) == false)
    #expect(
      ContentSurface.isAllowed(type: .record, surface: .maps, recordKind: "call_log") == false)
  }

  @Test func allowsSocialAndEphemeralShapes() {
    #expect(ContentSurface.isAllowed(type: .thread, surface: .photoSocial, recordKind: nil))
    #expect(ContentSurface.isAllowed(type: .image, surface: .photoSocial, recordKind: nil))
    #expect(
      ContentSurface.isAllowed(
        type: .record, surface: .photoSocial, recordKind: "social_profile"))
    #expect(ContentSurface.isAllowed(type: .thread, surface: .ephemeralChat, recordKind: nil))
  }

  @Test func parserRejectsUnknownSurfaceString() throws {
    let manifest = """
      {"schemaVersion":1,"id":"t","title":"t","sectorMap":[{"fragmentId":"f1","typeHint":"thread","integrity":1}],"verdict":{"questions":[{"id":"q1","prompt":"p","options":["a"],"correct":"a","supportedBy":["f1"]}]}}
      """.data(using: .utf8)!
    let fragment = """
      {"id":"f1","type":"thread","label":"x","surface":"tiktok","damage":{"profile":"block-loss","intensity":0.1,"seed":1},"content":{"participants":[{"entityId":"a","display":"A"}],"messages":[{"at":"2026-01-01T00:00:00Z","from":"a","text":"hi","corrupt":false}]}}
      """.data(using: .utf8)!
    do {
      _ = try parseCase(manifestData: manifest, fragmentFiles: [("f1.json", fragment)])
      Issue.record("unknown surface must fail parse")
    } catch let error as CaseFormatError {
      #expect(error.message.contains("unknown surface"))
    }
  }

  @Test func parserRejectsInvalidTypeSurfaceCombo() throws {
    let manifest = """
      {"schemaVersion":1,"id":"t","title":"t","sectorMap":[{"fragmentId":"f1","typeHint":"note","integrity":1}],"verdict":{"questions":[{"id":"q1","prompt":"p","options":["a"],"correct":"a","supportedBy":["f1"]}]}}
      """.data(using: .utf8)!
    let fragment = """
      {"id":"f1","type":"note","label":"x","surface":"photo_social","damage":{"profile":"block-loss","intensity":0.1,"seed":1},"content":{"title":"t","body":"b"}}
      """.data(using: .utf8)!
    do {
      _ = try parseCase(manifestData: manifest, fragmentFiles: [("f1.json", fragment)])
      Issue.record("invalid combo must fail parse")
    } catch let error as CaseFormatError {
      #expect(error.message.contains("invalid type/surface"))
    }
  }

  @Test func explicitSurfaceIsPreservedOnFragment() throws {
    let manifest = """
      {"schemaVersion":1,"id":"t","title":"t","sectorMap":[{"fragmentId":"f1","typeHint":"thread","integrity":1}],"verdict":{"questions":[{"id":"q1","prompt":"p","options":["a"],"correct":"a","supportedBy":["f1"]}]}}
      """.data(using: .utf8)!
    let fragment = """
      {"id":"f1","type":"thread","label":"x","surface":"photo_social","damage":{"profile":"block-loss","intensity":0.1,"seed":1},"content":{"participants":[{"entityId":"eli","display":"Eli"},{"entityId":"sable","display":"Sable"}],"messages":[{"at":"2026-01-01T00:00:00Z","from":"sable","text":"hey","corrupt":false}]}}
      """.data(using: .utf8)!
    let c = try parseCase(manifestData: manifest, fragmentFiles: [("f1.json", fragment)])
    #expect(c.fragments["f1"]?.surface == .photoSocial)
  }
}
