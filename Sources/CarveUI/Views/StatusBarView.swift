// Sources/CarveUI/Views/StatusBarView.swift
// In-fiction phone status chrome. Must feel like iOS — not a second OS chrome
// stacked under the real system bar (system bar is hidden by the app).

import SwiftUI
import CarveShell

struct StatusBarView: View {
  @Environment(\.carveTheme) private var theme
  /// Light glyphs over wallpaper; dark glyphs over light app chrome.
  var lightContent: Bool = false

  private var ink: Color {
    lightContent
      ? theme.palette.badgeText.color
      : theme.palette.statusBarContent.color
  }

  private var timeText: String {
    let f = DateFormatter()
    f.dateFormat = "h:mm"
    return f.string(from: Date())
  }

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      Text(timeText)
        .font(theme.fonts.statusBarFont)
        .fontWeight(.semibold)
        .foregroundStyle(ink)
        .monospacedDigit()

      Spacer(minLength: 0)

      if theme.statusBar.showsSignalGlyphs {
        HStack(spacing: theme.spacing.xs) {
          CellularBars(ink: ink)
          WifiGlyph(ink: ink)
            .frame(width: 15, height: 11)
          BatteryGlyph(ink: ink)
            .frame(width: 25, height: 12)
        }
      }
    }
    .padding(.horizontal, theme.statusBar.horizontalPadding)
    .frame(height: theme.statusBar.height)
  }
}

/// Originally drawn bars — not Apple glyph artwork.
private struct CellularBars: View {
  @Environment(\.carveTheme) private var theme
  let ink: Color

  var body: some View {
    HStack(alignment: .bottom, spacing: 1.5) {
      ForEach(0..<4, id: \.self) { i in
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.08, style: .continuous)
          .fill(ink.opacity(i == 3 ? 0.35 : 1))
          .frame(width: 3, height: 4 + CGFloat(i) * 2.2)
      }
    }
    .frame(height: 11, alignment: .bottom)
  }
}

private struct WifiGlyph: View {
  let ink: Color

  var body: some View {
    Canvas { context, size in
      let mid = CGPoint(x: size.width / 2, y: size.height * 0.92)
      for (i, scale) in [0.35, 0.62, 0.92].enumerated() {
        var path = Path()
        let r = size.width * 0.5 * scale
        path.addArc(
          center: mid,
          radius: r,
          startAngle: .degrees(210),
          endAngle: .degrees(330),
          clockwise: false
        )
        context.stroke(
          path,
          with: .color(ink.opacity(i == 0 ? 1 : 0.95)),
          style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
        )
      }
    }
  }
}

private struct BatteryGlyph: View {
  @Environment(\.carveTheme) private var theme
  let ink: Color

  var body: some View {
    HStack(spacing: 1) {
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.28, style: .continuous)
          .stroke(ink.opacity(0.45), lineWidth: 1)
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.15, style: .continuous)
          .fill(ink)
          .padding(2)
          .frame(width: 16)
      }
      .frame(width: 22, height: 11)
      Capsule()
        .fill(ink.opacity(0.45))
        .frame(width: 1.5, height: 4)
    }
  }
}
