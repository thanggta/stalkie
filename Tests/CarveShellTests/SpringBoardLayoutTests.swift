// Tests/CarveShellTests/SpringBoardLayoutTests.swift
// Why: equal gutters, dock alignment, and a non-clipped home indicator are
// structural SpringBoard cues. Overflowing bottom chrome is a fidelity bug.

import Testing
import CarveShell

struct SpringBoardLayoutTests {
  @Test func equalGuttersOnModernPhoneWidth() {
    let layout = SpringBoardLayout(screenWidth: 402, screenHeight: 874)
    #expect(layout.usesEqualGutters)
    #expect(layout.sideMargin == layout.columnGap)
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
    #expect(layout.widgetHeight >= 120)
    #expect(layout.widgetHeight <= 170)
    #expect(layout.homeIndicatorWidth >= 120)
    #expect(layout.pageDotSize < 10)
  }

  @Test func bottomChromeLeavesRoomForHomeIndicatorOnProHeights() {
    // iPhone 15/16/17 Pro-class logical heights.
    for height in [852.0, 874.0, 932.0] {
      let layout = SpringBoardLayout(screenWidth: 402, screenHeight: height)
      #expect(
        layout.fitsHomeIndicatorWithAtLeastOneIconRow,
        "height \(height): top+bottom chrome must leave room for ≥1 icon row + indicator")
      #expect(layout.maxPageRows >= 3, "height \(height) should fit a dense page")
      #expect(layout.maxPageIcons >= 12)
      // Budget identity: chrome + full grid of max rows must not exceed screen.
      let grid =
        Double(layout.maxPageRows) * layout.pageRowCellHeight
        + Double(max(0, layout.maxPageRows - 1)) * layout.rowGap
      let total = layout.topChromeHeight + grid + layout.bottomChromeHeight
      #expect(
        total <= height + 0.5,
        "height \(height): laid-out total \(total) exceeds screen")
    }
  }

  @Test func maxPageRowsShrinksOnShortScreens() {
    let tall = SpringBoardLayout(screenWidth: 390, screenHeight: 874)
    let short = SpringBoardLayout(screenWidth: 390, screenHeight: 700)
    #expect(short.maxPageRows <= tall.maxPageRows)
    #expect(short.fitsHomeIndicatorWithAtLeastOneIconRow)
  }

  @Test func bottomChromeHeightIncludesIndicatorBand() {
    let layout = SpringBoardLayout(screenWidth: 390, screenHeight: 844)
    let expected =
      layout.pageDotSize + layout.dotsBottomPadding
      + layout.dockHeight
      + layout.indicatorTopPadding + layout.homeIndicatorHeight + layout.indicatorBottomPadding
    #expect(abs(layout.bottomChromeHeight - expected) < 0.001)
    #expect(layout.bottomChromeHeight > layout.dockHeight)
  }
}
