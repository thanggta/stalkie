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
    // iPhone 17e (compact), 17 Pro, and 17 Pro Max logical dimensions.
    let devices: [(name: String, width: Double, height: Double)] = [
      ("iPhone 17e", 375.0, 667.0),
      ("iPhone 17 Pro", 402.0, 874.0),
      ("iPhone 17 Pro Max", 440.0, 956.0)
    ]
    for device in devices {
      let layout = SpringBoardLayout(screenWidth: device.width, screenHeight: device.height)
      #expect(
        layout.fitsHomeIndicatorWithAtLeastOneIconRow,
        "\(device.name): top+bottom chrome must leave room for ≥1 icon row + indicator")
      #expect(layout.maxPageRows >= 1, "\(device.name) must fit at least one row")
      // Budget identity: chrome + full grid of max rows must not exceed screen.
      let grid =
        Double(layout.maxPageRows) * layout.pageRowCellHeight
        + Double(max(0, layout.maxPageRows - 1)) * layout.rowGap
      let total = layout.topChromeHeight + grid + layout.bottomChromeHeight
      #expect(
        total <= device.height + 0.5,
        "\(device.name): laid-out total \(total) exceeds screen height \(device.height)")
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
