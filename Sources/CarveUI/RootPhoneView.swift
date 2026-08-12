// Sources/CarveUI/RootPhoneView.swift
// The phone shell. Overall feeling must read as a real unlocked phone —
// not a game menu with app icons glued on.

import SwiftUI
import CarveShell

public enum PhoneRoute: Hashable {
  case home
  case app(PhoneAppId)
  case fragment(String)
  case verdict
  case verdictResults
}

public struct RootPhoneView: View {
  public init() {}

  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @State private var path: [PhoneRoute] = []

  private var onHome: Bool { path.isEmpty }

  public var body: some View {
    ZStack(alignment: .top) {
      // App / home content fills the device.
      NavigationStack(path: $path) {
        HomeScreenView(path: $path)
          .navigationDestination(for: PhoneRoute.self) { route in
            switch route {
            case .home:
              HomeScreenView(path: $path)
            case .app(let appId):
              AppContainerView(appId: appId, path: $path)
            case .fragment(let id):
              FragmentHostView(fragmentId: id, path: $path)
            case .verdict:
              VerdictFlowView(path: $path)
            case .verdictResults:
              VerdictResultsView(path: $path)
            }
          }
      }
      .hideSystemNavigationChrome()

      VStack(spacing: 0) {
        StatusBarView(lightContent: statusBarLight)
          .allowsHitTesting(false)
        UnlockBannerStack(path: $path)
        Spacer(minLength: 0)
          .allowsHitTesting(false)
        if !onHome {
          HomeIndicator()
            .padding(.bottom, theme.spacing.xs)
            .allowsHitTesting(false)
        }
      }
    }
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .environment(\.carveTheme, session.theme)
    .hideSystemStatusChrome()
  }

  private var statusBarLight: Bool {
    // Wallpaper home + dark unlock surfaces use light glyphs.
    if onHome { return true }
    if case .some(.verdict) = path.first { return false }
    return false
  }
}

/// Thin home-indicator capsule — original geometry, not Apple artwork.
struct HomeIndicator: View {
  @Environment(\.carveTheme) private var theme

  var body: some View {
    Capsule()
      .fill(theme.palette.primaryText.color.opacity(0.22))
      .frame(width: 128, height: 5)
  }
}

struct UnlockBannerStack: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  /// Filing must not be interrupted — jumping to an app mid-verdict drops answers.
  private var isFiling: Bool {
    path.contains {
      switch $0 {
      case .verdict, .verdictResults: return true
      default: return false
      }
    }
  }

  var body: some View {
    if let notice = session.pendingNotices.first, !isFiling {
      Button {
        session.dismissNotice(notice.fragmentId)
        path = [.app(notice.appId)]
      } label: {
        // iOS-style notification banner: frosted card, app glyph, two lines.
        HStack(spacing: theme.spacing.sm) {
          AppGlyph(appId: notice.appId)
            .frame(width: 32, height: 32)
            .clipShape(
              RoundedRectangle(cornerRadius: theme.radii.appIcon * 0.45, style: .continuous)
            )

          VStack(alignment: .leading, spacing: 1) {
            Text(notice.appId.title.uppercased())
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.unlockBannerText.color.opacity(0.7))
            Text(notice.label)
              .font(theme.fonts.footnoteFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.unlockBannerText.color)
              .lineLimit(1)
          }
          Spacer(minLength: 0)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.sm)
        .background(
          theme.palette.unlockBannerBackground.color.opacity(0.92),
          in: RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
        )
        .overlay(
          RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
            .stroke(theme.palette.badgeText.color.opacity(0.08), lineWidth: 0.5)
        )
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.xs)
      }
      .buttonStyle(.plain)
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.spring(response: 0.35, dampingFraction: 0.85), value: notice.fragmentId)
    }
  }
}
