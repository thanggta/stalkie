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
  public func font(_ size: Double, textStyle: Font.TextStyle = .body, mono: Bool = false) -> Font {
    let name = mono ? monoFamily : family
    if mono {
      return .custom(name.hasPrefix(".") ? "Courier" : name, size: CGFloat(size), relativeTo: textStyle)
    }
    return .custom(name.hasPrefix(".") ? "" : name, size: CGFloat(size), relativeTo: textStyle)
  }

  public var largeTitleFont: Font { font(largeTitle, textStyle: .largeTitle) }
  public var titleFont: Font { font(title, textStyle: .title) }
  public var headlineFont: Font { font(headline, textStyle: .headline) }
  public var bodyFont: Font { font(body, textStyle: .body) }
  public var calloutFont: Font { font(callout, textStyle: .callout) }
  public var subheadlineFont: Font { font(subheadline, textStyle: .subheadline) }
  public var footnoteFont: Font { font(footnote, textStyle: .footnote) }
  public var captionFont: Font { font(caption, textStyle: .caption) }
  public var statusBarFont: Font { font(statusBar, textStyle: .caption2) }
  public var iconLabelFont: Font { font(iconLabel, textStyle: .caption) }
  public var bubbleFont: Font { font(bubble, textStyle: .body) }
  public var monoFont: Font { font(body, textStyle: .body, mono: true) }
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

extension View {
  /// Hide UIKit navigation chrome. No-op on macOS (SPM builds CarveUI there for lint).
  @ViewBuilder
  public func hideSystemNavigationChrome() -> some View {
    #if os(iOS)
    self
      .navigationBarBackButtonHidden(true)
      .toolbar(.hidden, for: .navigationBar)
    #else
    self
    #endif
  }

  /// Suppress the real device status bar so only the in-fiction one shows.
  @ViewBuilder
  public func hideSystemStatusChrome() -> some View {
    #if os(iOS)
    self
      .statusBarHidden(true)
      .persistentSystemOverlays(.hidden)
    #else
    self
    #endif
  }
}
