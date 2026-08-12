// Sources/CarveShell/Theme/SpringBoardLayout.swift
// Pure SpringBoard geometry. Equal gutters + bottom-chrome budget are data.

import Foundation

/// Screen-driven home metrics matching modern iPhone SpringBoard structure.
public struct SpringBoardLayout: Equatable, Sendable {
  public let screenWidth: Double
  public let screenHeight: Double
  public let iconSize: Double
  /// Side margin and inter-column gap (equal share of leftover width).
  public let gutter: Double
  public let sideMargin: Double
  public let columnGap: Double
  /// Glass extends past icons; outer dock inset keeps icons on page columns.
  public let dockGlassBleed: Double
  public let dockOuterInset: Double
  public let widgetHeight: Double
  public let widgetCornerRadius: Double
  public let rowGap: Double
  public let labelSpacing: Double
  public let iconLabelHeight: Double
  public let pageDotSize: Double
  public let pageDotSpacing: Double
  public let homeIndicatorWidth: Double
  public let homeIndicatorHeight: Double
  public let statusBandHeight: Double
  public let widgetBottomPadding: Double
  public let dotsBottomPadding: Double
  public let indicatorTopPadding: Double
  public let indicatorBottomPadding: Double
  public let dockVerticalPadding: Double

  public init(
    screenWidth: Double,
    screenHeight: Double,
    iconSize: Double = 60,
    dockGlassBleed: Double = 14,
    widgetHeight: Double = 140,
    widgetCornerRadius: Double = 22,
    rowGap: Double = 12,
    labelSpacing: Double = 5,
    iconLabelHeight: Double = 13,
    pageDotSize: Double = 6.5,
    pageDotSpacing: Double = 8,
    homeIndicatorWidth: Double = 139,
    homeIndicatorHeight: Double = 5,
    statusBandHeight: Double = 63,
    widgetBottomPadding: Double = 10,
    dotsBottomPadding: Double = 8,
    indicatorTopPadding: Double = 8,
    indicatorBottomPadding: Double = 8,
    dockVerticalPadding: Double = 11
  ) {
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.iconSize = iconSize
    let leftover = max(0, screenWidth - 4 * iconSize)
    let g = max(12, leftover / 5)
    self.gutter = g
    self.sideMargin = g
    self.columnGap = g
    self.dockGlassBleed = dockGlassBleed
    self.dockOuterInset = max(0, g - dockGlassBleed)
    self.widgetHeight = widgetHeight
    self.widgetCornerRadius = widgetCornerRadius
    self.rowGap = rowGap
    self.labelSpacing = labelSpacing
    self.iconLabelHeight = iconLabelHeight
    self.pageDotSize = pageDotSize
    self.pageDotSpacing = pageDotSpacing
    self.homeIndicatorWidth = homeIndicatorWidth
    self.homeIndicatorHeight = homeIndicatorHeight
    self.statusBandHeight = statusBandHeight
    self.widgetBottomPadding = widgetBottomPadding
    self.dotsBottomPadding = dotsBottomPadding
    self.indicatorTopPadding = indicatorTopPadding
    self.indicatorBottomPadding = indicatorBottomPadding
    self.dockVerticalPadding = dockVerticalPadding
  }

  /// First icon column left edge (page and dock icons share this x).
  public var firstIconMinX: Double { sideMargin }

  public var dockIconsAlignWithPage: Bool {
    abs((dockOuterInset + dockGlassBleed) - sideMargin) < 0.001
  }

  public var usesEqualGutters: Bool {
    abs(sideMargin - columnGap) < 0.001
  }

  /// Icon cell height including label (no inter-row gap).
  public var pageRowCellHeight: Double {
    iconSize + labelSpacing + iconLabelHeight
  }

  /// Dock glass height (icons + vertical padding, no labels).
  public var dockHeight: Double {
    iconSize + 2 * dockVerticalPadding
  }

  /// Fixed bottom stack: dots + dock + home indicator (must always fit on screen).
  public var bottomChromeHeight: Double {
    pageDotSize + dotsBottomPadding
      + dockHeight
      + indicatorTopPadding + homeIndicatorHeight + indicatorBottomPadding
  }

  /// Vertical budget reserved above the icon grid.
  public var topChromeHeight: Double {
    statusBandHeight + widgetHeight + widgetBottomPadding
  }

  /// Height available for labeled icon rows between top chrome and bottom chrome.
  public var iconGridAvailableHeight: Double {
    max(0, screenHeight - topChromeHeight - bottomChromeHeight)
  }

  /// Max labeled rows that fit without clipping bottom chrome / home indicator.
  public var maxPageRows: Int {
    let cell = pageRowCellHeight
    guard cell > 0, iconGridAvailableHeight >= cell else { return 0 }
    // n*cell + (n-1)*rowGap <= available
    // n*(cell+rowGap) <= available + rowGap
    let n = Int((iconGridAvailableHeight + rowGap) / (cell + rowGap))
    return max(0, min(6, n))
  }

  public var maxPageIcons: Int {
    maxPageRows * 4
  }

  /// True when at least one full icon row and the home indicator can share the screen.
  public var fitsHomeIndicatorWithAtLeastOneIconRow: Bool {
    maxPageRows >= 1 && bottomChromeHeight + topChromeHeight + pageRowCellHeight <= screenHeight + 0.5
  }
}
