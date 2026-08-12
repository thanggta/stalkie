// Sources/CarveShell/Theme/Theme.swift
//
// The entire 5.2.5 retreat plan. Every visual token lives here as data.
// Views read Theme; they never invent radii, fonts, or colors. A second
// theme ships from day one so "swappable" is proven, not aspirational.

import Foundation

/// sRGB 0…1. Converted to platform colors at the view boundary only.
public struct ThemeColor: Equatable, Sendable, Hashable {
  public let r: Double
  public let g: Double
  public let b: Double
  public let a: Double

  public init(r: Double, g: Double, b: Double, a: Double = 1) {
    self.r = r
    self.g = g
    self.b = b
    self.a = a
  }

  public static func gray(_ v: Double, a: Double = 1) -> ThemeColor {
    ThemeColor(r: v, g: v, b: v, a: a)
  }
}

public struct ThemePalette: Equatable, Sendable {
  public let screenBackground: ThemeColor
  public let elevatedBackground: ThemeColor
  public let groupedBackground: ThemeColor
  public let primaryText: ThemeColor
  public let secondaryText: ThemeColor
  public let tertiaryText: ThemeColor
  public let separator: ThemeColor
  public let accent: ThemeColor
  public let destructive: ThemeColor
  public let outgoingBubble: ThemeColor
  public let incomingBubble: ThemeColor
  public let outgoingBubbleText: ThemeColor
  public let incomingBubbleText: ThemeColor
  public let statusBarContent: ThemeColor
  public let iconLabel: ThemeColor
  public let badge: ThemeColor
  public let badgeText: ThemeColor
  public let unlockBannerBackground: ThemeColor
  public let unlockBannerText: ThemeColor
  public let corruptGlyph: ThemeColor
  public let homeWallpaperTop: ThemeColor
  public let homeWallpaperBottom: ThemeColor
  public let iconMessages: ThemeColor
  public let iconNotes: ThemeColor
  public let iconPhone: ThemeColor
  public let iconPhotos: ThemeColor
  public let iconPlaces: ThemeColor
  public let photoPlaceholder: ThemeColor

  public init(
    screenBackground: ThemeColor,
    elevatedBackground: ThemeColor,
    groupedBackground: ThemeColor,
    primaryText: ThemeColor,
    secondaryText: ThemeColor,
    tertiaryText: ThemeColor,
    separator: ThemeColor,
    accent: ThemeColor,
    destructive: ThemeColor,
    outgoingBubble: ThemeColor,
    incomingBubble: ThemeColor,
    outgoingBubbleText: ThemeColor,
    incomingBubbleText: ThemeColor,
    statusBarContent: ThemeColor,
    iconLabel: ThemeColor,
    badge: ThemeColor,
    badgeText: ThemeColor,
    unlockBannerBackground: ThemeColor,
    unlockBannerText: ThemeColor,
    corruptGlyph: ThemeColor,
    homeWallpaperTop: ThemeColor,
    homeWallpaperBottom: ThemeColor,
    iconMessages: ThemeColor,
    iconNotes: ThemeColor,
    iconPhone: ThemeColor,
    iconPhotos: ThemeColor,
    iconPlaces: ThemeColor,
    photoPlaceholder: ThemeColor
  ) {
    self.screenBackground = screenBackground
    self.elevatedBackground = elevatedBackground
    self.groupedBackground = groupedBackground
    self.primaryText = primaryText
    self.secondaryText = secondaryText
    self.tertiaryText = tertiaryText
    self.separator = separator
    self.accent = accent
    self.destructive = destructive
    self.outgoingBubble = outgoingBubble
    self.incomingBubble = incomingBubble
    self.outgoingBubbleText = outgoingBubbleText
    self.incomingBubbleText = incomingBubbleText
    self.statusBarContent = statusBarContent
    self.iconLabel = iconLabel
    self.badge = badge
    self.badgeText = badgeText
    self.unlockBannerBackground = unlockBannerBackground
    self.unlockBannerText = unlockBannerText
    self.corruptGlyph = corruptGlyph
    self.homeWallpaperTop = homeWallpaperTop
    self.homeWallpaperBottom = homeWallpaperBottom
    self.iconMessages = iconMessages
    self.iconNotes = iconNotes
    self.iconPhone = iconPhone
    self.iconPhotos = iconPhotos
    self.iconPlaces = iconPlaces
    self.photoPlaceholder = photoPlaceholder
  }
}

public struct ThemeRadii: Equatable, Sendable {
  public let appIcon: Double
  public let bubble: Double
  public let bubbleTail: Double
  public let card: Double
  public let chip: Double
  public let banner: Double

  public init(
    appIcon: Double,
    bubble: Double,
    bubbleTail: Double,
    card: Double,
    chip: Double,
    banner: Double
  ) {
    self.appIcon = appIcon
    self.bubble = bubble
    self.bubbleTail = bubbleTail
    self.card = card
    self.chip = chip
    self.banner = banner
  }
}

/// Font tokens as data. Views resolve via `theme.fonts.*` only — never
/// hardcode a face name or point size in a view body.
public struct ThemeFonts: Equatable, Sendable {
  public let family: String
  public let monoFamily: String
  public let largeTitle: Double
  public let title: Double
  public let headline: Double
  public let body: Double
  public let callout: Double
  public let subheadline: Double
  public let footnote: Double
  public let caption: Double
  public let statusBar: Double
  public let iconLabel: Double
  public let bubble: Double

  public init(
    family: String,
    monoFamily: String,
    largeTitle: Double,
    title: Double,
    headline: Double,
    body: Double,
    callout: Double,
    subheadline: Double,
    footnote: Double,
    caption: Double,
    statusBar: Double,
    iconLabel: Double,
    bubble: Double
  ) {
    self.family = family
    self.monoFamily = monoFamily
    self.largeTitle = largeTitle
    self.title = title
    self.headline = headline
    self.body = body
    self.callout = callout
    self.subheadline = subheadline
    self.footnote = footnote
    self.caption = caption
    self.statusBar = statusBar
    self.iconLabel = iconLabel
    self.bubble = bubble
  }
}

public struct ThemeBubbleGeometry: Equatable, Sendable {
  public let maxWidthFraction: Double
  public let horizontalPadding: Double
  public let verticalPadding: Double
  public let stackSpacing: Double
  public let groupSpacing: Double
  /// 0 = fully rounded (iOS-like); higher = flatter sides (fallback).
  public let squareness: Double

  public init(
    maxWidthFraction: Double,
    horizontalPadding: Double,
    verticalPadding: Double,
    stackSpacing: Double,
    groupSpacing: Double,
    squareness: Double
  ) {
    self.maxWidthFraction = maxWidthFraction
    self.horizontalPadding = horizontalPadding
    self.verticalPadding = verticalPadding
    self.stackSpacing = stackSpacing
    self.groupSpacing = groupSpacing
    self.squareness = squareness
  }
}

public enum ThemeIconShapeKind: String, Equatable, Sendable {
  case roundedSquare
  case circle
  case hexagon
}

public struct ThemeIconShape: Equatable, Sendable {
  public let kind: ThemeIconShapeKind
  public let size: Double
  public let gridSpacing: Double
  public let labelSpacing: Double

  public init(kind: ThemeIconShapeKind, size: Double, gridSpacing: Double, labelSpacing: Double) {
    self.kind = kind
    self.size = size
    self.gridSpacing = gridSpacing
    self.labelSpacing = labelSpacing
  }
}

public struct ThemeStatusBarLayout: Equatable, Sendable {
  public let height: Double
  public let horizontalPadding: Double
  public let showsCarrier: Bool
  public let showsSignalGlyphs: Bool
  public let timeCentered: Bool

  public init(
    height: Double,
    horizontalPadding: Double,
    showsCarrier: Bool,
    showsSignalGlyphs: Bool,
    timeCentered: Bool
  ) {
    self.height = height
    self.horizontalPadding = horizontalPadding
    self.showsCarrier = showsCarrier
    self.showsSignalGlyphs = showsSignalGlyphs
    self.timeCentered = timeCentered
  }
}

public struct ThemeSpacing: Equatable, Sendable {
  public let xxs: Double
  public let xs: Double
  public let sm: Double
  public let md: Double
  public let lg: Double
  public let xl: Double
  public let xxl: Double

  public init(xxs: Double, xs: Double, sm: Double, md: Double, lg: Double, xl: Double, xxl: Double) {
    self.xxs = xxs
    self.xs = xs
    self.sm = sm
    self.md = md
    self.lg = lg
    self.xl = xl
    self.xxl = xxl
  }
}

public struct Theme: Equatable, Sendable, Identifiable {
  public let id: String
  public let displayName: String
  public let palette: ThemePalette
  public let radii: ThemeRadii
  public let fonts: ThemeFonts
  public let bubble: ThemeBubbleGeometry
  public let icon: ThemeIconShape
  public let statusBar: ThemeStatusBarLayout
  public let spacing: ThemeSpacing

  public init(
    id: String,
    displayName: String,
    palette: ThemePalette,
    radii: ThemeRadii,
    fonts: ThemeFonts,
    bubble: ThemeBubbleGeometry,
    icon: ThemeIconShape,
    statusBar: ThemeStatusBarLayout,
    spacing: ThemeSpacing
  ) {
    self.id = id
    self.displayName = displayName
    self.palette = palette
    self.radii = radii
    self.fonts = fonts
    self.bubble = bubble
    self.icon = icon
    self.statusBar = statusBar
    self.spacing = spacing
  }

  public static let allBuiltIn: [Theme] = [.iosLookalike, .fallbackWorkstation]

  public static func builtIn(id: String) -> Theme {
    allBuiltIn.first { $0.id == id } ?? .iosLookalike
  }
}
