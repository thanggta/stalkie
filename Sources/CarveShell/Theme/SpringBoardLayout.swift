// Sources/CarveShell/Theme/SpringBoardLayout.swift
// Pure SpringBoard geometry. Equal gutters are data — unit-testable without UI.

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
  public let pageDotSize: Double
  public let pageDotSpacing: Double
  public let homeIndicatorWidth: Double
  public let homeIndicatorHeight: Double

  public init(
    screenWidth: Double,
    screenHeight: Double,
    iconSize: Double = 60,
    dockGlassBleed: Double = 14,
    widgetHeight: Double = 152,
    widgetCornerRadius: Double = 22,
    rowGap: Double = 15,
    pageDotSize: Double = 6.5,
    pageDotSpacing: Double = 8,
    homeIndicatorWidth: Double = 139,
    homeIndicatorHeight: Double = 5
  ) {
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.iconSize = iconSize
    // leftover = 2 margins + 3 gaps across 4 icons → divide by 5.
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
    self.pageDotSize = pageDotSize
    self.pageDotSpacing = pageDotSpacing
    self.homeIndicatorWidth = homeIndicatorWidth
    self.homeIndicatorHeight = homeIndicatorHeight
  }

  /// First icon column left edge (page and dock icons share this x).
  public var firstIconMinX: Double { sideMargin }

  /// Whether dock outer inset + glass bleed places dock icons on page columns.
  public var dockIconsAlignWithPage: Bool {
    abs((dockOuterInset + dockGlassBleed) - sideMargin) < 0.001
  }

  /// Side margin equals column gap (equal-gutter SpringBoard rule).
  public var usesEqualGutters: Bool {
    abs(sideMargin - columnGap) < 0.001
  }
}
