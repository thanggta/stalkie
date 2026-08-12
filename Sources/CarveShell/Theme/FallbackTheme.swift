// Sources/CarveShell/Theme/FallbackTheme.swift
// Visibly different retreat theme. Proves the iOS lookalike is data, not
// hardcoded view geometry. Dark workstation chrome, mono type, hex icons.

extension Theme {
  public static let fallbackWorkstation = Theme(
    id: "fallback_workstation",
    displayName: "Workstation",
    palette: ThemePalette(
      screenBackground: ThemeColor(r: 0.07, g: 0.08, b: 0.1),
      elevatedBackground: ThemeColor(r: 0.12, g: 0.13, b: 0.16),
      groupedBackground: ThemeColor(r: 0.09, g: 0.1, b: 0.12),
      primaryText: ThemeColor(r: 0.86, g: 0.9, b: 0.86),
      secondaryText: ThemeColor(r: 0.55, g: 0.65, b: 0.55),
      tertiaryText: ThemeColor(r: 0.4, g: 0.48, b: 0.4),
      separator: ThemeColor(r: 0.2, g: 0.28, b: 0.2),
      accent: ThemeColor(r: 0.3, g: 0.95, b: 0.55),
      destructive: ThemeColor(r: 0.95, g: 0.35, b: 0.3),
      outgoingBubble: ThemeColor(r: 0.12, g: 0.28, b: 0.18),
      incomingBubble: ThemeColor(r: 0.16, g: 0.17, b: 0.2),
      outgoingBubbleText: ThemeColor(r: 0.75, g: 1.0, b: 0.8),
      incomingBubbleText: ThemeColor(r: 0.86, g: 0.9, b: 0.86),
      statusBarContent: ThemeColor(r: 0.3, g: 0.95, b: 0.55),
      iconLabel: ThemeColor(r: 0.55, g: 0.75, b: 0.55),
      badge: ThemeColor(r: 0.3, g: 0.95, b: 0.55),
      badgeText: ThemeColor(r: 0.05, g: 0.08, b: 0.05),
      unlockBannerBackground: ThemeColor(r: 0.08, g: 0.22, b: 0.12),
      unlockBannerText: ThemeColor(r: 0.55, g: 1.0, b: 0.65),
      corruptGlyph: ThemeColor(r: 0.95, g: 0.55, b: 0.2),
      homeWallpaperTop: ThemeColor(r: 0.04, g: 0.06, b: 0.05),
      homeWallpaperBottom: ThemeColor(r: 0.08, g: 0.12, b: 0.09),
      iconMessages: ThemeColor(r: 0.12, g: 0.35, b: 0.2),
      iconNotes: ThemeColor(r: 0.35, g: 0.4, b: 0.15),
      iconPhone: ThemeColor(r: 0.15, g: 0.4, b: 0.25),
      iconPhotos: ThemeColor(r: 0.3, g: 0.25, b: 0.35),
      iconPlaces: ThemeColor(r: 0.15, g: 0.3, b: 0.35),
      photoPlaceholder: ThemeColor(r: 0.18, g: 0.2, b: 0.18)
    ),
    radii: ThemeRadii(
      appIcon: 4,
      bubble: 2,
      bubbleTail: 0,
      card: 2,
      chip: 2,
      banner: 2
    ),
    fonts: ThemeFonts(
      family: "Menlo",
      monoFamily: "Menlo",
      largeTitle: 22,
      title: 16,
      headline: 14,
      body: 13,
      callout: 13,
      subheadline: 12,
      footnote: 11,
      caption: 10,
      statusBar: 10,
      iconLabel: 9,
      bubble: 13
    ),
    bubble: ThemeBubbleGeometry(
      maxWidthFraction: 0.85,
      horizontalPadding: 10,
      verticalPadding: 6,
      stackSpacing: 4,
      groupSpacing: 8,
      squareness: 1
    ),
    icon: ThemeIconShape(
      kind: .hexagon,
      size: 52,
      gridSpacing: 20,
      labelSpacing: 8
    ),
    statusBar: ThemeStatusBarLayout(
      height: 44,
      horizontalPadding: 16,
      showsCarrier: false,
      showsSignalGlyphs: true,
      timeCentered: true
    ),
    spacing: ThemeSpacing(xxs: 2, xs: 4, sm: 6, md: 10, lg: 14, xl: 20, xxl: 28)
  )
}
