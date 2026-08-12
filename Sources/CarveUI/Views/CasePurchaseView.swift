// Sources/CarveUI/Views/CasePurchaseView.swift
// Plain one-time unlock. No urgency, no preselected offer, no subscription.

import SwiftUI
import CarveCommerce
import CarveShell

public struct CasePurchaseView: View {
  let entry: CatalogEntry
  let product: StoreProduct?
  let phase: PurchasePhase
  let loadState: ProductLoadState
  let onBuy: () -> Void
  let onRestore: () -> Void
  let onClose: () -> Void

  @Environment(\.carveTheme) private var theme

  public init(
    entry: CatalogEntry,
    product: StoreProduct?,
    phase: PurchasePhase,
    loadState: ProductLoadState,
    onBuy: @escaping () -> Void,
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    self.entry = entry
    self.product = product
    self.phase = phase
    self.loadState = loadState
    self.onBuy = onBuy
    self.onRestore = onRestore
    self.onClose = onClose
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Button("Close", action: onClose)
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.accent.color)
          .frame(minHeight: 44)
          .accessibilityIdentifier("purchase-close")
        Spacer()
      }

      Text(entry.title)
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.primaryText.color)
        .accessibilityAddTraits(.isHeader)

      Text(entry.summary)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

      Text("One-time purchase. Unlocks \(entry.title) only. Not a subscription.")
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .accessibilityIdentifier("purchase-terms")

      if let product {
        Text(product.displayPrice)
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.primaryText.color)
          .accessibilityLabel("Price \(product.displayPrice)")
          .accessibilityIdentifier("purchase-price")
      }

      Text(statusCopy)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(statusColor)
        .accessibilityIdentifier("purchase-state")
        .accessibilityValue(statusCopy)

      Button(action: onBuy) {
        Text(buyTitle)
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.badgeText.color)
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(
            theme.palette.accent.color,
            in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .disabled(!canBuy)
      .accessibilityElement(children: .ignore)
      .accessibilityIdentifier("purchase-buy")
      .accessibilityLabel(buyTitle)
      .accessibilityHint("One-time purchase. Not a subscription.")

      Button("Restore Purchases", action: onRestore)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.accent.color)
        .frame(minHeight: 44)
        .accessibilityIdentifier("purchase-restore")
        .accessibilityHint("Refreshes what you already bought. Does not erase progress.")

      Spacer()
    }
    .padding(theme.spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .accessibilityIdentifier("purchase-screen")
  }

  private var canBuy: Bool {
    switch phase {
    case .purchasing, .purchased, .pending, .revoked:
      return false
    default:
      return product != nil && loadState == .loaded
    }
  }

  private var buyTitle: String {
    if let product {
      return "Buy \(entry.title) · \(product.displayPrice)"
    }
    return "Buy \(entry.title)"
  }

  private var statusCopy: String {
    switch phase {
    case .idle:
      switch loadState {
      case .loading: return "Loading price…"
      case .failed: return "The store couldn’t load this case. Try again later."
      case .unavailable: return "This case isn’t available to buy right now."
      default: return product == nil ? "Loading price…" : "Available as a one-time purchase."
      }
    case .purchasing:
      return "Purchasing…"
    case .purchased:
      return "Purchased. You can open this case now."
    case .pending:
      return "This purchase is waiting for approval. The case stays locked until then."
    case .cancelled:
      return "Purchase cancelled. Nothing was charged."
    case .failed(let message):
      return message
    case .unavailable:
      return "Purchases aren’t available on this device right now."
    case .revoked:
      return "Access was removed. Your progress is still here if access returns."
    }
  }

  private var statusColor: Color {
    switch phase {
    case .failed, .revoked:
      return theme.palette.destructive.color
    case .cancelled, .pending:
      return theme.palette.secondaryText.color
    default:
      return theme.palette.secondaryText.color
    }
  }
}
