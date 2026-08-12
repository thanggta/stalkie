// Tests/CarveShellTests/SpringBoardLayoutTests.swift
// Why: equal gutters and dock/page column alignment are the structural cues
// that stop the home shell reading as a sparse game lobby. These must fail
// if SpringBoardLayout math regresses.

import Testing
import CarveShell

struct SpringBoardLayoutTests {
  @Test func equalGuttersOnModernPhoneWidth() {
    // iPhone 17 Pro logical width ≈ 402pt
    let layout = SpringBoardLayout(screenWidth: 402, screenHeight: 874)
    #expect(layout.usesEqualGutters)
    #expect(layout.sideMargin == layout.columnGap)
    #expect(layout.gutter > 12)
    // 4×60 + 5×gutter fills the width exactly.
    let used = 4 * layout.iconSize + 5 * layout.gutter
    #expect(abs(used - 402) < 0.01)
  }

  @Test func dockIconsAlignWithPageColumns() {
    let layout = SpringBoardLayout(screenWidth: 393, screenHeight: 852)
    #expect(layout.dockIconsAlignWithPage)
    #expect(abs(layout.firstIconMinX - (layout.dockOuterInset + layout.dockGlassBleed)) < 0.001)
  }

  @Test func widgetAndChromeProportionsAreSpringBoardScale() {
    let layout = SpringBoardLayout(screenWidth: 390, screenHeight: 844)
    // Medium widget is roughly two icon rows, not a short banner.
    #expect(layout.widgetHeight >= 140)
    #expect(layout.widgetHeight <= 170)
    #expect(layout.widgetCornerRadius >= 18)
    #expect(layout.homeIndicatorWidth >= 120)
    #expect(layout.pageDotSize < 10)
  }

  @Test func narrowWidthStillKeepsEqualGutters() {
    let layout = SpringBoardLayout(screenWidth: 320, screenHeight: 568, iconSize: 60)
    #expect(layout.usesEqualGutters)
    #expect(layout.gutter >= 12)
  }
}
