// Sources/CarveUI/Views/CaseLibraryView.swift
// Game-layer catalog. Not one of the apps on his phone.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import CarveCommerce
import CarveShell

public struct CaseLibraryView: View {
  let catalog: CaseCatalog
  let snapshot: EntitlementSnapshot
  let progress: (String) -> CaseProgress
  let canLaunch: (CatalogEntry) -> Bool
  let onOpen: (CatalogEntry) -> Void
  let onPurchase: (CatalogEntry) -> Void
  let onReplay: (CatalogEntry) -> Void
  let onRestore: () -> Void
  let onDeleteAllProgress: () -> Void
  var showDeveloperReset: Bool = false
  var onDeveloperReset: (() -> Void)? = nil

  @Environment(\.carveTheme) private var theme
  @State private var confirmDeleteAll = false
  @State private var showManage = false
  @State private var replayTarget: CatalogEntry?

  public init(
    catalog: CaseCatalog,
    snapshot: EntitlementSnapshot,
    progress: @escaping (String) -> CaseProgress,
    canLaunch: @escaping (CatalogEntry) -> Bool,
    onOpen: @escaping (CatalogEntry) -> Void,
    onPurchase: @escaping (CatalogEntry) -> Void,
    onReplay: @escaping (CatalogEntry) -> Void,
    onRestore: @escaping () -> Void,
    onDeleteAllProgress: @escaping () -> Void,
    showDeveloperReset: Bool = false,
    onDeveloperReset: (() -> Void)? = nil
  ) {
    self.catalog = catalog
    self.snapshot = snapshot
    self.progress = progress
    self.canLaunch = canLaunch
    self.onOpen = onOpen
    self.onPurchase = onPurchase
    self.onReplay = onReplay
    self.onRestore = onRestore
    self.onDeleteAllProgress = onDeleteAllProgress
    self.showDeveloperReset = showDeveloperReset
    self.onDeveloperReset = onDeveloperReset
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("CARVE")
            .font(theme.fonts.largeTitleFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.primaryText.color)
            .accessibilityAddTraits(.isHeader)
          Text("His phones. One at a time.")
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
        }

        ForEach(catalog.entries) { entry in
          Button {
            handlePrimary(entry)
          } label: {
            CaseCardView(
              entry: entry,
              access: accessCopy(entry),
              progress: progress(entry.caseId),
              onReplay: { replayTarget = entry }
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("case-card-\(entry.caseId)")
        }

        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Button("Restore Purchases", action: onRestore)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.accent.color)
            .frame(minHeight: 44)
            .accessibilityIdentifier("restore-purchases")
            .accessibilityHint("Refreshes what you already bought. Does not erase progress.")

          Button("Manage progress…") {
            showManage = true
          }
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.tertiaryText.color)
          .frame(minHeight: 44)
          .accessibilityIdentifier("manage-progress")
          .accessibilityHint("Delete local saves. Purchases are not removed.")
        }
        .padding(.top, theme.spacing.sm)

        if showDeveloperReset, let onDeveloperReset {
          Button("Developer reset", action: onDeveloperReset)
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .accessibilityIdentifier("developer-reset")
        }
      }
      .padding(theme.spacing.lg)
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
    .accessibilityIdentifier("case-library")
    .confirmationDialog(
      "Manage local progress",
      isPresented: $showManage,
      titleVisibility: .visible
    ) {
      Button("Delete all progress", role: .destructive) {
        confirmDeleteAll = true
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Purchases stay. Only saves on this device can be removed.")
    }
    .confirmationDialog(
      "Delete all local progress?",
      isPresented: $confirmDeleteAll,
      titleVisibility: .visible
    ) {
      Button("Delete all progress", role: .destructive, action: onDeleteAllProgress)
        .accessibilityIdentifier("delete-all-progress")
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Purchases stay. Only the saves on this device are removed.")
    }
    .confirmationDialog(
      "Replay this case?",
      isPresented: Binding(
        get: { replayTarget != nil },
        set: { if !$0 { replayTarget = nil } }),
      titleVisibility: .visible
    ) {
      Button("Replay from the start", role: .destructive) {
        if let entry = replayTarget {
          onReplay(entry)
        }
        replayTarget = nil
      }
      Button("Cancel", role: .cancel) { replayTarget = nil }
    } message: {
      Text("Only this case is reset. Other cases and purchases stay.")
    }
  }

  private func handlePrimary(_ entry: CatalogEntry) {
    if entry.availability == .comingSoon { return }
    // Free cases always request launch; AppBootstrap still enforces entitlement.
    if entry.access == .free || canLaunch(entry) {
      onOpen(entry)
    } else {
      onPurchase(entry)
    }
  }

  private func productStatus(_ entry: CatalogEntry) -> EntitlementStatus {
    guard let productId = entry.productId else { return .unknown }
    return snapshot.status(for: productId)
  }

  private func accessCopy(_ entry: CatalogEntry) -> String {
    if entry.availability == .comingSoon { return "Coming soon" }
    switch entry.access {
    case .free:
      return "Free"
    case .paid:
      switch productStatus(entry) {
      case .owned:
        return "Owned"
      case .revoked:
        return "Access removed"
      case .notOwned, .unknown:
        if let product = entry.productId.flatMap({ snapshot.product(id: $0) }) {
          return product.displayPrice
        }
        switch snapshot.loadState {
        case .failed, .unavailable:
          return "Unavailable"
        default:
          return "Locked"
        }
      }
    }
  }
}

struct CaseCardView: View {
  let entry: CatalogEntry
  let access: String
  let progress: CaseProgress
  let onReplay: () -> Void

  @Environment(\.carveTheme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      artwork
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .clipped()
        .clipShape(
          RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
        )
        .accessibilityHidden(true)

      HStack(spacing: theme.spacing.xs) {
        stateChip(progressLabel)
        stateChip(access)
        Spacer(minLength: 0)
      }

      Text(entry.title)
        .font(theme.fonts.titleFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)

      Text(entry.summary)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: theme.spacing.sm) {
        Text(primaryTitle)
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.badgeText.color)
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(
            primaryEnabled
              ? theme.palette.accent.color
              : theme.palette.secondaryText.color.opacity(0.45),
            in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
          )

        if progress != .notStarted && (access == "Owned" || access == "Free") {
          Button("Replay", action: onReplay)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.primaryText.color)
            .frame(minWidth: 88, minHeight: 44)
            .accessibilityIdentifier("case-replay-\(entry.caseId)")
        }
      }
    }
    .padding(theme.spacing.md)
    .background(
      theme.palette.elevatedBackground.color,
      in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
        .stroke(theme.palette.separator.color.opacity(0.65), lineWidth: 0.5)
    )
    .contentShape(Rectangle())
    .accessibilityLabel(entry.title)
    .accessibilityValue("\(progressLabel). \(access). \(entry.summary)")
  }

  private func stateChip(_ text: String) -> some View {
    Text(text)
      .font(theme.fonts.captionFont)
      .fontWeight(.semibold)
      .foregroundStyle(theme.palette.secondaryText.color)
      .padding(.horizontal, theme.spacing.sm)
      .padding(.vertical, theme.spacing.xxs)
      .background(
        theme.palette.groupedBackground.color,
        in: Capsule()
      )
  }

  private var primaryEnabled: Bool {
    access != "Coming soon" && access != "Unavailable"
  }

  private var primaryTitle: String {
    if access == "Coming soon" { return "Coming soon" }
    if access == "Unavailable" { return "Unavailable" }
    if access != "Free" && access != "Owned" && access != "Access removed" {
      // Locked paid — show Unlock / price-led CTA
      if access.hasPrefix("$") || access.contains("€") || access.contains("£") {
        return "Unlock · \(access)"
      }
      if access == "Locked" { return "Unlock" }
    }
    switch progress {
    case .notStarted: return "Open"
    case .inProgress: return "Continue"
    case .filed: return "Review verdict"
    }
  }

  private var progressLabel: String {
    switch progress {
    case .notStarted: return "Not started"
    case .inProgress: return "In progress"
    case .filed: return "Filed"
    }
  }

  @ViewBuilder
  private var artwork: some View {
    if let image = CatalogArtwork.image(named: entry.artwork) {
      image
        .resizable()
        .scaledToFill()
    } else {
      theme.palette.groupedBackground.color
    }
  }
}

enum CatalogArtwork {
  static func image(named path: String) -> Image? {
    guard let root = CatalogLoader.resolveCasesRoot() else { return nil }
    let url = root.appendingPathComponent(path)
    #if canImport(UIKit)
    if let ui = UIImage(contentsOfFile: url.path) {
      return Image(uiImage: ui)
    }
    #endif
    return nil
  }
}
