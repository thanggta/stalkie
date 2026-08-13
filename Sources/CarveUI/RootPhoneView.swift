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
  public var onLeavePhone: (() -> Void)?

  public init(onLeavePhone: (() -> Void)? = nil) {
    self.onLeavePhone = onLeavePhone
  }

  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        PersistenceWarningBanner()
        UnlockBannerStack(path: $path)
        Spacer(minLength: 0)
          .allowsHitTesting(false)
      }
      .ignoresSafeArea(edges: .top)

      if let onLeavePhone {
        VStack {
          HStack {
            Button(action: onLeavePhone) {
              Text("Cases")
                .font(theme.fonts.footnoteFont)
                .foregroundStyle(theme.palette.badgeText.color)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
                .background(
                  theme.palette.primaryText.color.opacity(0.28),
                  in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("library-back")
            .accessibilityLabel("Back to case library")
            .frame(minWidth: 44, minHeight: 44)
            Spacer()
          }
          .padding(.horizontal, theme.spacing.sm)
          Spacer()
        }
        .padding(.top, theme.statusBar.height)
      }
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

struct PersistenceWarningBanner: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme

  var body: some View {
    if let failure = session.persistenceFailure {
      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        Text(failure.playerMessage)
          .font(theme.fonts.footnoteFont)
          .foregroundStyle(theme.palette.unlockBannerText.color)
          .fixedSize(horizontal: false, vertical: true)
        Button(PlayerFacingCopy.saveFailedRetry) {
          session.retryPersistence()
        }
        .font(theme.fonts.captionFont)
        .foregroundStyle(theme.palette.badgeText.color)
        .accessibilityIdentifier("persistence-retry")
      }
      .padding(theme.spacing.sm)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        theme.palette.destructive.color.opacity(0.92),
        in: RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
      )
      .padding(.horizontal, theme.spacing.md)
      .padding(.top, theme.spacing.xs)
      .accessibilityIdentifier("persistence-warning")
    }
  }
}

struct UnlockBannerStack: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
      .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
      .animation(
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85),
        value: notice.fragmentId)
      .onAppear {
        let id = notice.fragmentId
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
          session.dismissNotice(id)
        }
      }
    }
  }
}
