// Tests/CarveShellTests/HomePagingLogicTests.swift
// Why: compact phones must not drop Links/Decide when filler apps fill the grid.
// Paging policy lives in pure layout math + ordered lists (no caseId branches).

import Foundation
import Testing
import CarveShell

struct HomePagingLogicTests {
  @Test func compactPhoneKeepsAtLeastOneFullIconRow() {
    // iPhone SE-class height budget.
    let layout = SpringBoardLayout(screenWidth: 375, screenHeight: 667)
    #expect(layout.maxPageRows >= 1)
    #expect(layout.fitsHomeIndicatorWithAtLeastOneIconRow)
  }

  @Test func primaryEvidenceAppsFitOnFirstPageBudget() {
    // Primary page order (mirrors HomeScreenView) must fit within max icons
    // on a modern Pro-height phone so discovery tools are not page-2 only.
    let layout = SpringBoardLayout(screenWidth: 393, screenHeight: 852)
    let primaryCount = 12 // facetime…reminders before filler
    #expect(
      layout.maxPageIcons >= primaryCount,
      "first page must hold evidence apps without truncation (\(layout.maxPageIcons) < \(primaryCount))")
  }

  @Test func twoBuiltInThemesStillExistForRetreat() {
    #expect(Theme.allBuiltIn.count >= 2)
  }
}
