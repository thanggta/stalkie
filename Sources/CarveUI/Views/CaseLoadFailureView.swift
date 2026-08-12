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
      Text(PlayerFacingCopy.loadFailedTitle)
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.destructive.color)

      Text(message)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.primaryText.color)

      Spacer()
    }
    .padding(theme.spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
  }
}
