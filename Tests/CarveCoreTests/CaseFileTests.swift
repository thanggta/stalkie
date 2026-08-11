import Testing
@testable import CarveCore

struct CaseFileTests {
  @Test func totalCarveCostSumsEveryFragmentCost() {
    // INV-2 is checked against the total, so hidden fragments must be included.
    let caseFile = CaseFile(
      schemaVersion: 1,
      id: "test",
      title: "Test",
      cycleBudget: 10,
      sectorMap: [
        SectorEntry(fragmentId: "a", typeHint: .note, integrity: 0.9, carveCost: 6),
        SectorEntry(fragmentId: "b", typeHint: .note, integrity: 0.5, carveCost: 9),
      ],
      questions: [],
      fragments: [:]
    )
    #expect(caseFile.totalCarveCost == 15)
  }
}
