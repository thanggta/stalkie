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

      // In-fiction status chrome sits in the hardware safe area (next to
      // Dynamic Island), not *below* it — ignoresSafeArea is required.
      // Transparent regions must not steal taps from the home grid/dock.
      VStack(spacing: 0) {
        StatusBarView(lightContent: statusBarLight)
          .allowsHitTesting(false)
        UnlockBannerStack(path: $path)
        Spacer(minLength: 0)
          .allowsHitTesting(false)
      }
      .ignoresSafeArea(edges: .top)
    }
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .environment(\.carveTheme, session.theme)
    .hideSystemStatusChrome()
  }

  private var statusBarLight: Bool {
    if onHome { return true }
    if case .some(.verdict) = path.first { return false }
    return false
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
        // Compact floating notification — iOS lock-screen banner language.
        HStack(spacing: theme.spacing.sm) {
          AppGlyph(appId: notice.appId)
            .frame(width: 36, height: 36)
            .clipShape(
              RoundedRectangle(cornerRadius: theme.radii.appIcon * 0.45, style: .continuous)
            )

          VStack(alignment: .leading, spacing: 1) {
            HStack {
              Text(notice.appId.title)
                .font(theme.fonts.captionFont)
                .fontWeight(.semibold)
                .foregroundStyle(theme.palette.unlockBannerText.color.opacity(0.7))
              Spacer(minLength: 0)
              Text("now")
                .font(theme.fonts.captionFont)
                .foregroundStyle(theme.palette.unlockBannerText.color.opacity(0.45))
            }
            Text(notice.label)
              .font(theme.fonts.footnoteFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.unlockBannerText.color)
              .lineLimit(2)
          }
        }
        .padding(.horizontal, theme.spacing.sm + 2)
        .padding(.vertical, theme.spacing.sm)
        .background {
          RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
            .fill(.ultraThinMaterial)
        }
        .background {
          RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
            .fill(theme.palette.unlockBannerBackground.color.opacity(0.55))
        }
        .overlay(
          RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
            .stroke(theme.palette.badgeText.color.opacity(0.12), lineWidth: 0.5)
        )
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.xs)
      }
      .buttonStyle(.plain)
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.spring(response: 0.35, dampingFraction: 0.85), value: notice.fragmentId)
      .onAppear {
        let id = notice.fragmentId
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
          session.dismissNotice(id)
        }
      }
    }
  }
}
