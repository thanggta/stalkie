// Sources/CarveUI/Views/VerdictResultsView.swift
// After filing: being wrong lands; what she missed is visible. No percentage.

import SwiftUI
import CarveCore
import CarveShell

struct VerdictResultsView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  var body: some View {
    VStack(spacing: 0) {
      AppNavBar(title: "Filed", backLabel: "Home") {
        path = []
      }

      if let report = session.filedReport {
        results(report)
      } else {
        Text("No verdict has been filed.")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .padding(theme.spacing.lg)
        Spacer()
      }
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
  }

  private func results(_ report: VerdictReport) -> some View {
    let wrong = report.results.filter { !$0.isCorrect }
    let right = report.results.filter(\.isCorrect)
    let prompts = Dictionary(
      uniqueKeysWithValues: session.caseFile.questions.map { ($0.id, $0.prompt) })

    return ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        Text("What you decided")
          .font(theme.fonts.titleFont)
          .foregroundStyle(theme.palette.primaryText.color)
          .accessibilityIdentifier("verdict-results-title")
          .accessibilityAddTraits(.isHeader)

        // No percentage. Accuracy is felt, not printed.
        if wrong.isEmpty {
          Text("You got every question right. That does not mean this was easy to live with.")
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.secondaryText.color)
        } else {
          Text(
            wrong.count == 1
              ? "One of your calls was wrong."
              : "\(wrong.count) of your calls were wrong."
          )
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.destructive.color)
        }

        if !wrong.isEmpty {
          Text("Where you were wrong")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .padding(.top, theme.spacing.sm)

          ForEach(wrong, id: \.questionId) { result in
            wrongCard(result, prompt: prompts[result.questionId] ?? result.questionId)
          }
        }

        if !right.isEmpty {
          Text("What you saw clearly")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .padding(.top, theme.spacing.sm)

          ForEach(right, id: \.questionId) { result in
            rightRow(result, prompt: prompts[result.questionId] ?? result.questionId)
          }
        }

        missedSection

        Button {
          path = []
        } label: {
          Text("Put the phone down")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.md)
            .background(
              theme.palette.unlockBannerBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, theme.spacing.md)
      }
      .padding(theme.spacing.lg)
    }
  }

  private func wrongCard(_ result: QuestionResult, prompt: String) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(prompt)
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)

      Text("You said \(PlayerFacingCopy.verdictOptionLabel(result.given)).")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.destructive.color)

      Text("It was \(PlayerFacingCopy.verdictOptionLabel(result.correct)).")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.primaryText.color)


    }
    .padding(theme.spacing.md)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      theme.palette.elevatedBackground.color,
      in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
    )
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
        .stroke(theme.palette.destructive.color.opacity(0.45), lineWidth: 1)
    )
  }

  private func rightRow(_ result: QuestionResult, prompt: String) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
      Text(prompt)
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)
      Text(PlayerFacingCopy.verdictOptionLabel(result.correct))
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.primaryText.color)
    }
    .padding(.vertical, theme.spacing.xs)
  }

  private var missedSection: some View {
    let missed = session.missedFragments
    return VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("What you never opened")
        .font(theme.fonts.captionFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
        .padding(.top, theme.spacing.sm)

      if missed.isEmpty {
        Text("You opened everything that was on the phone.")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
      } else {
        Text(
          missed.count == 1
            ? "One thing on this phone you never opened. A second look starts there."
            : "\(missed.count) things on this phone you never opened. A second look starts there."
        )
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

        ForEach(missed, id: \.id) { fragment in
          HStack {
            Text(fragment.label)
              .font(theme.fonts.subheadlineFont)
              .foregroundStyle(theme.palette.primaryText.color)
            Spacer()
            Text(PhoneAppId.hosting(fragment: fragment).title)
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.tertiaryText.color)
          }
          .padding(.vertical, theme.spacing.xs)
          .overlay(alignment: .bottom) {
            Rectangle()
              .fill(theme.palette.separator.color)
              .frame(height: 0.5)
          }
        }
      }
    }
  }

}
