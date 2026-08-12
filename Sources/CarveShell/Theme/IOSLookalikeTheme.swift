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
      separator: ThemeColor.gray(0.82),
      accent: ThemeColor(r: 0.0, g: 0.478, b: 1.0),
      destructive: ThemeColor(r: 1.0, g: 0.231, b: 0.188),
      outgoingBubble: ThemeColor(r: 0.04, g: 0.52, b: 1.0),
      incomingBubble: ThemeColor.gray(0.91),
      outgoingBubbleText: ThemeColor.gray(1.0),
      incomingBubbleText: ThemeColor.gray(0.0),
      statusBarContent: ThemeColor.gray(0.0),
      iconLabel: ThemeColor.gray(1.0),
      badge: ThemeColor(r: 1.0, g: 0.231, b: 0.188),
      badgeText: ThemeColor.gray(1.0),
      unlockBannerBackground: ThemeColor(r: 0.11, g: 0.11, b: 0.12),
      unlockBannerText: ThemeColor.gray(1.0),
      corruptGlyph: ThemeColor.gray(0.55),
      homeWallpaperTop: ThemeColor(r: 0.12, g: 0.22, b: 0.48),
      homeWallpaperBottom: ThemeColor(r: 0.48, g: 0.22, b: 0.38),
      // Real-system icon hues (approx.) so the grid reads as a stock phone.
      iconMessages: ThemeColor(r: 0.20, g: 0.78, b: 0.35),
      iconNotes: ThemeColor(r: 1.0, g: 0.80, b: 0.0),
      iconPhone: ThemeColor(r: 0.20, g: 0.78, b: 0.35),
      iconPhotos: ThemeColor(r: 0.95, g: 0.35, b: 0.55),
      iconPlaces: ThemeColor(r: 0.30, g: 0.72, b: 0.42),
      photoPlaceholder: ThemeColor.gray(0.90)
    ),
    radii: ThemeRadii(
      // ~22.5% of 60pt continuous mask (SpringBoard SBIconImageInfo range).
      appIcon: 13.5,
      bubble: 18,
      bubbleTail: 4,
      // Medium widget continuous corner (~22pt on modern phones).
      card: 22,
      chip: 10,
      // Dock glass continuous corner — large, soft, not a “card.”
      banner: 34
    ),
    fonts: ThemeFonts(
      family: ".AppleSystemUIFont",
      monoFamily: "Menlo",
      largeTitle: 34,
      title: 17,
      headline: 17,
      body: 17,
      callout: 16,
      subheadline: 15,
      footnote: 13,
      caption: 11,
      statusBar: 16,
      // SpringBoard labels read smaller/lighter than body.
      iconLabel: 11,
      bubble: 17
    ),
    bubble: ThemeBubbleGeometry(
      maxWidthFraction: 0.75,
      horizontalPadding: 12,
      verticalPadding: 8,
      stackSpacing: 2,
      groupSpacing: 6,
      squareness: 0
    ),
    icon: ThemeIconShape(
      kind: .roundedSquare,
      size: 60,
      // Fallback only — home computes equal gutters from width.
      gridSpacing: 27,
      // Icon bottom → label baseline gap.
      labelSpacing: 5
    ),
    statusBar: ThemeStatusBarLayout(
      // Dynamic Island band from physical top (overlay ignores safe area).
      height: 59,
      horizontalPadding: 27,
      showsCarrier: false,
      showsSignalGlyphs: true,
      timeCentered: false
    ),
    spacing: ThemeSpacing(xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32),
    homeWallpaperAsset: "ios_home"
  )
}
