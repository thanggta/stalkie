import Testing
@testable import CarveCore

struct CaseFileTests {
  @Test func sectorForResolvesByFragmentId() {
    let caseFile = CaseFile(
      schemaVersion: 1,
      id: "test",
      title: "Test",
      sectorMap: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.5),
      ],
      questions: [],
      fragments: [:]
    )
    #expect(caseFile.sectorFor("a")?.integrity == 0.9)
    #expect(caseFile.sectorFor("ghost") == nil)
  }
}
