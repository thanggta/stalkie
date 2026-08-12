// Sources/CarveUI/Theme/Color+Theme.swift
// Bridge ThemeColor → SwiftUI. Literals allowed here only (lint allowlist).

import SwiftUI
import CarveShell

extension ThemeColor {
  public var color: Color {
    Color(.sRGB, red: r, green: g, blue: b, opacity: a)
  }
}

extension ThemeFonts {
  public func font(_ size: Double, mono: Bool = false) -> Font {
    let name = mono ? monoFamily : family
    if name.hasPrefix(".") {
      return .system(size: size)
    }
    return .custom(name, size: size)
  }

  public var largeTitleFont: Font { font(largeTitle) }
  public var titleFont: Font { font(title) }
  public var headlineFont: Font { font(headline) }
  public var bodyFont: Font { font(body) }
  public var calloutFont: Font { font(callout) }
  public var subheadlineFont: Font { font(subheadline) }
  public var footnoteFont: Font { font(footnote) }
  public var captionFont: Font { font(caption) }
  public var statusBarFont: Font { font(statusBar) }
  public var iconLabelFont: Font { font(iconLabel) }
  public var bubbleFont: Font { font(bubble) }
  public var monoFont: Font { font(body, mono: true) }
}

private struct CarveThemeKey: EnvironmentKey {
  static let defaultValue: Theme = .iosLookalike
}

extension EnvironmentValues {
  public var carveTheme: Theme {
    get { self[CarveThemeKey.self] }
    set { self[CarveThemeKey.self] = newValue }
  }
}
