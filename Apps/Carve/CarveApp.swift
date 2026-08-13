// Apps/Carve/CarveApp.swift
import SwiftUI
import CarveCommerce
import CarveCore
import CarveShell
import CarveUI

@main
struct CarveApp: App {
  @StateObject private var bootstrap: AppBootstrap

  init() {
    _bootstrap = StateObject(wrappedValue: AppBootstrap())
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch bootstrap.phase {
        case .loading:
          PhoneLaunchView(theme: Theme.iosLookalike)
            .accessibilityIdentifier("launch-loading")
        case .library:
          CaseLibraryView(
            catalog: bootstrap.catalog,
            snapshot: bootstrap.entitlements.snapshot,
            progress: bootstrap.progress(for:),
            canLaunch: bootstrap.canLaunch,
            onOpen: { bootstrap.openCase($0.caseId) },
            onPurchase: { bootstrap.showPurchase($0) },
            onReplay: { bootstrap.replay($0.caseId) },
            onRestore: { Task { await bootstrap.restorePurchases() } },
            onDeleteAllProgress: { bootstrap.deleteAllProgress() },
            showDeveloperReset: AppBootstrap.developerToolsEnabled,
            onDeveloperReset: { bootstrap.resetProgress() }
          )
          .environment(\.carveTheme, Theme.iosLookalike)
        case .phone(let session):
          RootPhoneView(onLeavePhone: { bootstrap.returnToLibrary() })
            .environmentObject(session)
            .environment(\.carveTheme, session.theme)
            .accessibilityIdentifier("phone-root")
        case .purchase(let entry):
          CasePurchaseView(
            entry: entry,
            product: entry.productId.flatMap { bootstrap.entitlements.snapshot.product(id: $0) },
            phase: bootstrap.purchasePhase,
            loadState: bootstrap.entitlements.snapshot.loadState,
            onBuy: { Task { await bootstrap.buy(entry) } },
            onRestore: { Task { await bootstrap.restorePurchases() } },
            onClose: { bootstrap.returnToLibrary() }
          )
          .environment(\.carveTheme, Theme.iosLookalike)
        case .pickCase(let ids):
          DebugCasePickerView(ids: ids) { id in
            bootstrap.openCase(id)
          }
        case .failed(let message):
          CaseLoadFailureView(message: message)
            .accessibilityIdentifier("case-load-failure")
        }
      }
    }
  }
}

struct DebugCasePickerView: View {
  let ids: [String]
  let onSelect: (String) -> Void
  private let theme = Theme.iosLookalike

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("Choose a phone")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("Development only. Production opens the library.")
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)

      if ids.isEmpty {
        Text("No cases were found in the bundle.")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.destructive.color)
      } else {
        ForEach(ids, id: \.self) { id in
          Button {
            onSelect(id)
          } label: {
            Text(id.replacingOccurrences(of: "_", with: " "))
              .font(theme.fonts.headlineFont)
              .foregroundStyle(theme.palette.badgeText.color)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(theme.spacing.md)
              .background(
                theme.palette.elevatedBackground.color,
                in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
              )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("case-pick-\(id)")
        }
      }
      Spacer()
    }
    .padding(theme.spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .environment(\.carveTheme, theme)
    .accessibilityIdentifier("case-picker")
  }
}

public struct PhoneLaunchView: View {
  let theme: Theme

  public init(theme: Theme) {
    self.theme = theme
  }

  public var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          theme.palette.homeWallpaperTop.color,
          theme.palette.homeWallpaperBottom.color,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: theme.spacing.md) {
        RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
          .fill(theme.palette.elevatedBackground.color.opacity(0.18))
          .frame(width: theme.icon.size * 1.4, height: theme.icon.size * 1.4)
          .overlay {
            Image(systemName: "lock.open.fill")
              .font(theme.fonts.font(28))
              .foregroundStyle(theme.palette.badgeText.color.opacity(0.9))
          }
        Text("Unlocking…")
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.85))
      }
    }
    .environment(\.carveTheme, theme)
  }
}
