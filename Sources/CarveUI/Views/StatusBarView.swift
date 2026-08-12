// Sources/CarveUI/Views/StatusBarView.swift
// In-fiction phone status chrome. Sits *in* the Dynamic Island band
// (overlay ignores top safe area), not stacked under it.

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
        HStack(spacing: theme.spacing.xs + 2) {
          CellularBars(ink: ink)
          WifiGlyph(ink: ink)
            .frame(width: 16, height: 12)
          BatteryGlyph(ink: ink, level: 0.78)
        }
      }
    }
    // Island-band alignment: time/trailing sit mid-island, not under it.
    .padding(.horizontal, theme.statusBar.horizontalPadding)
    .padding(.top, 17)
    .frame(height: theme.statusBar.height, alignment: .top)
  }
}

private struct CellularBars: View {
  @Environment(\.carveTheme) private var theme
  let ink: Color

  var body: some View {
    HStack(alignment: .bottom, spacing: 1.5) {
      ForEach(0..<4, id: \.self) { i in
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.08, style: .continuous)
          .fill(ink.opacity(i == 3 ? 0.35 : 1))
          .frame(width: 3.2, height: 4.5 + CGFloat(i) * 2.4)
      }
    }
    .frame(height: 12, alignment: .bottom)
  }
}

private struct WifiGlyph: View {
  let ink: Color

  var body: some View {
    Canvas { context, size in
      let mid = CGPoint(x: size.width / 2, y: size.height * 0.95)
      for (i, scale) in [0.32, 0.6, 0.92].enumerated() {
        var path = Path()
        let r = size.width * 0.5 * scale
        path.addArc(
          center: mid,
          radius: r,
          startAngle: .degrees(215),
          endAngle: .degrees(325),
          clockwise: false
        )
        context.stroke(
          path,
          with: .color(ink.opacity(i == 0 ? 1 : 0.95)),
          style: StrokeStyle(lineWidth: 1.7, lineCap: .round)
        )
      }
      let d: CGFloat = 1.8
      context.fill(
        Path(ellipseIn: CGRect(x: mid.x - d / 2, y: mid.y - d, width: d, height: d)),
        with: .color(ink)
      )
    }
  }
}

private struct BatteryGlyph: View {
  @Environment(\.carveTheme) private var theme
  let ink: Color
  var level: CGFloat = 0.75

  var body: some View {
    HStack(spacing: 1.5) {
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.28, style: .continuous)
          .stroke(ink.opacity(0.4), lineWidth: 1)
          .frame(width: 25, height: 12)
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.15, style: .continuous)
          .fill(ink)
          .frame(width: max(2, (25 - 4) * level), height: 8)
          .padding(.leading, 2)
      }
      .frame(width: 25, height: 12)
      Capsule()
        .fill(ink.opacity(0.4))
        .frame(width: 1.6, height: 5)
    }
  }
}
