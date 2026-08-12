// Sources/CarveUI/Views/FragmentHostView.swift
import SwiftUI
import CarveCore
import CarveShell

struct FragmentHostView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let fragmentId: String
  @Binding var path: [PhoneRoute]

  var body: some View {
    Group {
      if let fragment = session.caseFile.fragments[fragmentId],
        session.isVisible(fragmentId)
      {
        VStack(spacing: 0) {
          Spacer().frame(height: theme.statusBar.height)
          AppNavBar(title: shortTitle(fragment), backLabel: "Back") {
            if path.count > 1 { path.removeLast() } else { path = [] }
          }
          content(for: fragment)
        }
        .background(theme.palette.screenBackground.color.ignoresSafeArea())
        .hideSystemNavigationChrome()
        .onAppear {
          session.openFragment(fragmentId)
        }
      } else {
        VStack(spacing: theme.spacing.md) {
          Spacer().frame(height: theme.statusBar.height)
          Text("Not recovered")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
          Button("Back") {
            if path.count > 1 { path.removeLast() } else { path = [] }
          }
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.accent.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.palette.screenBackground.color)
      }
    }
  }

  @ViewBuilder
  private func content(for fragment: Fragment) -> some View {
    switch fragment.type {
    case .thread:
      ThreadDetailView(fragment: fragment)
    case .note:
      NoteDetailView(fragment: fragment)
    case .record:
      RecordDetailView(fragment: fragment)
    case .image:
      ImageDetailView(fragment: fragment)
    case .audio:
      Text("Audio not supported in v1")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private func shortTitle(_ fragment: Fragment) -> String {
    switch fragment.type {
    case .thread:
      return (try? FragmentContent.thread(fragment))?.counterpartyDisplay ?? fragment.label
    case .note:
      return (try? FragmentContent.note(fragment))?.title ?? fragment.label
    default:
      return fragment.label
    }
  }
}
