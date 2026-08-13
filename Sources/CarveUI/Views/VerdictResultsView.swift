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
    let questionsById = Dictionary(
      uniqueKeysWithValues: session.caseFile.questions.map { ($0.id, $0) })

    return ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        Text("What you decided")
          .font(theme.fonts.titleFont)
          .fontWeight(.bold)
          .foregroundStyle(theme.palette.primaryText.color)
          .accessibilityIdentifier("verdict-results-title")
          .accessibilityAddTraits(.isHeader)

        // No percentage. Accuracy is felt, not printed.
        if wrong.isEmpty {
          Text("You got every call right. That does not mean this was easy to live with.")
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.secondaryText.color)
        } else {
          Text(
            wrong.count == 1
              ? "One of your calls was wrong."
              : "\(wrong.count) of your calls were wrong."
          )
          .font(theme.fonts.headlineFont)
          .fontWeight(.bold)
          .foregroundStyle(theme.palette.destructive.color)
        }

        if !wrong.isEmpty {
          Text("Where you were wrong")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .padding(.top, theme.spacing.sm)

          ForEach(wrong, id: \.questionId) { result in
            if let q = questionsById[result.questionId] {
              wrongCard(result, question: q)
            }
          }
        }

        if !right.isEmpty {
          Text("What you saw clearly")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .padding(.top, theme.spacing.sm)

          ForEach(right, id: \.questionId) { result in
            if let q = questionsById[result.questionId] {
              rightRow(result, question: q)
            }
          }
        }

        missedSection

        Button {
          path = []
        } label: {
          Text("Put the phone down")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
              theme.palette.unlockBannerBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("verdict-results-done")
        .padding(.top, theme.spacing.md)
      }
      .padding(theme.spacing.lg)
    }
  }

  private func wrongCard(_ result: QuestionResult, question: VerdictQuestion) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(question.prompt)
        .font(theme.fonts.headlineFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)

      VStack(alignment: .leading, spacing: theme.spacing.xxs) {
        Text("You believed: \(displayOption(result.given))")
          .font(theme.fonts.bodyFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.destructive.color)

        Text("What was true: \(displayOption(result.correct))")
          .font(theme.fonts.bodyFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.primaryText.color)
      }

      if let rationale = question.rationale, !rationale.isEmpty {
        VStack(alignment: .leading, spacing: 2) {
          Text("Why it looked that way")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.tertiaryText.color)
          Text(rationale)
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, theme.spacing.xxs)
      }

      if let evidenceHint = question.evidenceHint, !evidenceHint.isEmpty {
        VStack(alignment: .leading, spacing: 2) {
          Text("Evidence hint")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.tertiaryText.color)
          Text(evidenceHint)
            .font(theme.fonts.footnoteFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, theme.spacing.xxs)
      }

      let supportingLabels = question.supportedBy.compactMap { session.caseFile.fragments[$0]?.label }
      if !supportingLabels.isEmpty {
        HStack(spacing: theme.spacing.xs) {
          Image(systemName: "doc.text.magnifyingglass")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.accent.color)
          Text("Supporting evidence: \(supportingLabels.joined(separator: ", "))")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .lineLimit(2)
        }
        .padding(.top, theme.spacing.xs)
      }
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

  private func rightRow(_ result: QuestionResult, question: VerdictQuestion) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
      Text(question.prompt)
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)
      Text(displayOption(result.correct))
        .font(theme.fonts.bodyFont)
        .fontWeight(.medium)
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

  private func displayOption(_ raw: String) -> String {
    if raw.isEmpty { return "(nothing)" }
    return raw
      .split(separator: "_")
      .map { part in
        guard let first = part.first else { return String(part) }
        return String(first).uppercased() + part.dropFirst()
      }
      .joined(separator: " ")
  }
}
