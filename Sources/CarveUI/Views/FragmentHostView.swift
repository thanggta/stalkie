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
          fragmentChrome(for: fragment)
          content(for: fragment)
        }
        .background(theme.palette.screenBackground.color.ignoresSafeArea())
        .hideSystemNavigationChrome()
        .onAppear {
          session.openFragment(fragmentId)
        }
      } else {
        VStack(spacing: theme.spacing.md) {
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
  private func fragmentChrome(for fragment: Fragment) -> some View {
    if fragment.type == .thread {
      ThreadNavBar(
        title: shortTitle(fragment),
        onBack: {
          if path.count > 1 { path.removeLast() } else { path = [] }
        }
      )
    } else {
      AppNavBar(title: shortTitle(fragment), backLabel: "Back") {
        if path.count > 1 { path.removeLast() } else { path = [] }
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

/// iMessage conversation header: back + contact avatar/name centered.
struct ThreadNavBar: View {
  @Environment(\.carveTheme) private var theme
  let title: String
  let onBack: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(theme.fonts.titleFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.accent.color)
          .frame(width: 44, height: 44, alignment: .leading)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Back")

      Spacer(minLength: 0)

      VStack(spacing: 2) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [
                  theme.palette.secondaryText.color.opacity(0.35),
                  theme.palette.tertiaryText.color.opacity(0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          Text(monogram)
            .font(theme.fonts.captionFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.badgeText.color)
        }
        .frame(width: 36, height: 36)

        Text(title)
          .font(theme.fonts.captionFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.primaryText.color)
          .lineLimit(1)
      }

      Spacer(minLength: 0)

      // Balance the back chevron so the contact stays centered.
      Color.clear.frame(width: 44, height: 44)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.bottom, theme.spacing.xs)
    .background(theme.palette.elevatedBackground.color.opacity(0.96))
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(theme.palette.separator.color)
        .frame(height: 0.33)
    }
  }

  private var monogram: String {
    let parts = title.split(separator: " ")
    if parts.count >= 2, let a = parts[0].first, let b = parts[1].first {
      return "\(a)\(b)".uppercased()
    }
    if let first = parts.first?.first {
      return String(first).uppercased()
    }
    return "?"
  }
}
