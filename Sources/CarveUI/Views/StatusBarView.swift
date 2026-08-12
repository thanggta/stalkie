// Apps/Carve/Views/StatusBarView.swift
import SwiftUI
import CarveShell

struct StatusBarView: View {
  @Environment(\.carveTheme) private var theme
  @EnvironmentObject private var session: GameSession

  private var timeText: String {
    let f = DateFormatter()
    f.dateFormat = "h:mm"
    return f.string(from: Date())
  }

  var body: some View {
    ZStack {
      if theme.statusBar.timeCentered {
        Text(timeText)
          .font(theme.fonts.statusBarFont)
          .foregroundStyle(theme.palette.statusBarContent.color)
      }
      HStack {
        HStack(spacing: theme.spacing.xs) {
          if !theme.statusBar.timeCentered {
            Text(timeText)
              .font(theme.fonts.statusBarFont)
              .foregroundStyle(theme.palette.statusBarContent.color)
          }
          if theme.statusBar.showsCarrier {
            Text("Carrier")
              .font(theme.fonts.statusBarFont)
              .foregroundStyle(theme.palette.statusBarContent.color)
          }
        }
        Spacer()
        HStack(spacing: theme.spacing.xs) {
          if theme.statusBar.showsSignalGlyphs {
            SignalBars()
            Text("5G")
              .font(theme.fonts.statusBarFont)
              .foregroundStyle(theme.palette.statusBarContent.color)
          }
          ThemeMenuButton()
        }
      }
    }
    .padding(.horizontal, theme.statusBar.horizontalPadding)
    .frame(height: theme.statusBar.height)
    .background(theme.palette.elevatedBackground.color.opacity(0.92))
  }
}

/// Originally drawn bars — not Apple glyph artwork.
private struct SignalBars: View {
  @Environment(\.carveTheme) private var theme

  var body: some View {
    HStack(alignment: .bottom, spacing: 1.5) {
      ForEach(0..<4, id: \.self) { i in
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.15, style: .continuous)
          .fill(theme.palette.statusBarContent.color)
          .frame(width: 3, height: 4 + CGFloat(i) * 2.5)
      }
    }
  }
}

private struct ThemeMenuButton: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme

  var body: some View {
    Menu {
      ForEach(Theme.allBuiltIn) { t in
        Button {
          session.setTheme(t.id)
        } label: {
          HStack {
            Text(t.displayName)
            if session.themeId == t.id {
              Text("✓")
            }
          }
        }
      }
    } label: {
      Text(session.theme.displayName)
        .font(theme.fonts.captionFont)
        .foregroundStyle(theme.palette.accent.color)
    }
  }
}
