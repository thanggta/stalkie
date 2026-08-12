// Sources/CarveShell/Theme/IOSLookalikeTheme.swift
// iOS-lookalike tokens (DR-8). Geometry and palette approximate the platform
// language without shipping Apple artwork.

extension Theme {
  public static let iosLookalike = Theme(
    id: "ios_lookalike",
    displayName: "Phone",
    palette: ThemePalette(
      screenBackground: ThemeColor.gray(1.0),
      elevatedBackground: ThemeColor.gray(1.0),
      groupedBackground: ThemeColor.gray(0.95),
      primaryText: ThemeColor.gray(0.0),
      secondaryText: ThemeColor.gray(0.45),
      tertiaryText: ThemeColor.gray(0.6),
      separator: ThemeColor.gray(0.85),
      accent: ThemeColor(r: 0.0, g: 0.48, b: 1.0),
      destructive: ThemeColor(r: 1.0, g: 0.23, b: 0.19),
      outgoingBubble: ThemeColor(r: 0.04, g: 0.52, b: 1.0),
      incomingBubble: ThemeColor.gray(0.91),
      outgoingBubbleText: ThemeColor.gray(1.0),
      incomingBubbleText: ThemeColor.gray(0.0),
      statusBarContent: ThemeColor.gray(0.0),
      iconLabel: ThemeColor.gray(1.0),
      badge: ThemeColor(r: 1.0, g: 0.23, b: 0.19),
      badgeText: ThemeColor.gray(1.0),
      unlockBannerBackground: ThemeColor(r: 0.15, g: 0.15, b: 0.18),
      unlockBannerText: ThemeColor.gray(1.0),
      corruptGlyph: ThemeColor.gray(0.55),
      homeWallpaperTop: ThemeColor(r: 0.15, g: 0.22, b: 0.45),
      homeWallpaperBottom: ThemeColor(r: 0.45, g: 0.35, b: 0.55),
      iconMessages: ThemeColor(r: 0.04, g: 0.52, b: 1.0),
      iconNotes: ThemeColor(r: 0.98, g: 0.82, b: 0.2),
      iconPhone: ThemeColor(r: 0.2, g: 0.78, b: 0.35),
      iconPhotos: ThemeColor(r: 0.95, g: 0.4, b: 0.55),
      iconPlaces: ThemeColor(r: 0.25, g: 0.55, b: 0.95),
      photoPlaceholder: ThemeColor.gray(0.85)
    ),
    radii: ThemeRadii(
      appIcon: 13.5,
      bubble: 18,
      bubbleTail: 4,
      card: 12,
      chip: 8,
      banner: 14
    ),
    fonts: ThemeFonts(
      family: ".AppleSystemUIFont",
      monoFamily: "Menlo",
      largeTitle: 34,
      title: 20,
      headline: 17,
      body: 17,
      callout: 16,
      subheadline: 15,
      footnote: 13,
      caption: 12,
      statusBar: 12,
      iconLabel: 11,
      bubble: 17
    ),
    bubble: ThemeBubbleGeometry(
      maxWidthFraction: 0.72,
      horizontalPadding: 12,
      verticalPadding: 8,
      stackSpacing: 2,
      groupSpacing: 10,
      squareness: 0
    ),
    icon: ThemeIconShape(
      kind: .roundedSquare,
      size: 60,
      gridSpacing: 16,
      labelSpacing: 6
    ),
    statusBar: ThemeStatusBarLayout(
      height: 24,
      horizontalPadding: 16,
      showsCarrier: true,
      showsSignalGlyphs: true,
      timeCentered: false
    ),
    spacing: ThemeSpacing(xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32)
  )
}
