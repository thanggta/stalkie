// Sources/CarveUI/RootPhoneView.swift
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

  public var body: some View {
    VStack(spacing: 0) {
      StatusBarView()
      UnlockBannerStack(path: $path)
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
    }
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .environment(\.carveTheme, session.theme)
  }
}

struct UnlockBannerStack: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  var body: some View {
    if let notice = session.pendingNotices.first {
      Button {
        session.dismissNotice(notice.fragmentId)
        path = [.app(notice.appId)]
      } label: {
        HStack(spacing: theme.spacing.sm) {
          VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text("Something new appeared")
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.unlockBannerText.color.opacity(0.75))
            Text(notice.label)
              .font(theme.fonts.headlineFont)
              .foregroundStyle(theme.palette.unlockBannerText.color)
              .lineLimit(1)
          }
          Spacer(minLength: theme.spacing.sm)
          Text(notice.appId.title)
            .font(theme.fonts.footnoteFont)
            .foregroundStyle(theme.palette.unlockBannerText.color)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(
              theme.palette.accent.color.opacity(0.25),
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
          theme.palette.unlockBannerBackground.color,
          in: RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
        )
        .padding(.horizontal, theme.spacing.sm)
        .padding(.top, theme.spacing.xs)
      }
      .buttonStyle(.plain)
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.spring(response: 0.35, dampingFraction: 0.85), value: notice.fragmentId)
    }
  }
}
