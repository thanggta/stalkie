// Sources/CarveUI/Views/CaseLoadFailureView.swift
// Visible load failure — never hand the player an empty fake phone (fail loud).

import SwiftUI
import CarveShell

public struct CaseLoadFailureView: View {
  public let message: String

  public init(message: String) {
    self.message = message
  }

  @Environment(\.carveTheme) private var theme

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      Text("Case failed to load")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.destructive.color)

      Text(
        "The phone cannot open without a valid case bundle. This is not an empty case — load failed."
      )
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.primaryText.color)

      Text(message)
        .font(theme.fonts.monoFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .textSelection(.enabled)

      Spacer()
    }
    .padding(theme.spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
  }
}
