// Sources/CarveUI/Views/VerdictFlowView.swift
// Forced complete filing (DR-11). Progress is pacing, not a resource bar.

import SwiftUI
import CarveCore
import CarveShell

struct VerdictFlowView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  @State private var phase: Phase = .intro
  @State private var sectionIndex: Int = 0
  @State private var showIncomplete = false

  private enum Phase: Equatable {
    case intro
    case sections
    case review
    case confirm
  }

  /// Three thematic beats so fifteen questions are paced, not cut.
  private var sections: [[VerdictQuestion]] {
    let qs = session.caseFile.questions
    guard !qs.isEmpty else { return [] }
    let size = max(1, (qs.count + 2) / 3)
    var result: [[VerdictQuestion]] = []
    var i = 0
    while i < qs.count {
      let end = min(i + size, qs.count)
      result.append(Array(qs[i..<end]))
      i = end
    }
    return result
  }

  private var sectionTitles: [String] {
    [
      "What happened",
      "Who they are to each other",
      "What you are going to believe",
    ]
  }

  var body: some View {
    VStack(spacing: 0) {
      AppNavBar(title: navTitle, backLabel: "Home") {
        goBack()
      }

      switch phase {
      case .intro:
        introBody
      case .sections:
        sectionBody
      case .review:
        reviewBody
      case .confirm:
        confirmBody
      }
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
    .onAppear {
      if session.isFiled {
        path = [.verdictResults]
      }
    }
  }

  private var navTitle: String {
    switch phase {
    case .intro: return "Decide"
    case .sections:
      return "\(session.answeredCount)/\(session.caseFile.questions.count)"
    case .review: return "Review"
    case .confirm: return "File"
    }
  }

  private var introBody: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        Text("You are about to accuse someone.")
          .font(theme.fonts.titleFont)
          .foregroundStyle(theme.palette.primaryText.color)

        Text(
          "Not in a courtroom. In your head, and then out loud to yourself. Every question is required. Guessing is still a decision."
        )
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

        Text(
          "There is no score while you answer. When you file, you live with it."
        )
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

        Button {
          phase = .sections
          sectionIndex = 0
        } label: {
          Text("I am ready to answer")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.md)
            .background(
              theme.palette.destructive.color,
              in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("verdict-ready")
        .padding(.top, theme.spacing.md)
      }
      .padding(theme.spacing.lg)
    }
  }

  private var sectionBody: some View {
    let sections = self.sections
    let safeIndex = min(sectionIndex, max(sections.count - 1, 0))
    let questions = sections.isEmpty ? [] : sections[safeIndex]
    let title = safeIndex < sectionTitles.count
      ? sectionTitles[safeIndex]
      : "Questions"

    return VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        Text("Part \(safeIndex + 1) of \(max(sections.count, 1))")
          .font(theme.fonts.captionFont)
          .foregroundStyle(theme.palette.tertiaryText.color)
        Text(title)
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.primaryText.color)
        progressBar
      }
      .padding(theme.spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(theme.palette.elevatedBackground.color)

      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
          ForEach(questions, id: \.id) { question in
            questionCard(question)
          }
        }
        .padding(theme.spacing.md)
      }

      HStack(spacing: theme.spacing.md) {
        if safeIndex > 0 {
          Button("Back") {
            sectionIndex = safeIndex - 1
          }
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.accent.color)
        }
        Spacer()
        Button(safeIndex + 1 >= sections.count ? "Review answers" : "Next part") {
          if sectionComplete(questions) {
            showIncomplete = false
            if safeIndex + 1 >= sections.count {
              phase = .review
            } else {
              sectionIndex = safeIndex + 1
            }
          } else {
            showIncomplete = true
          }
        }
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.badgeText.color)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
          theme.palette.accent.color,
          in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
        )
        .accessibilityIdentifier("verdict-next")
      }
      .padding(theme.spacing.md)
      .background(theme.palette.elevatedBackground.color)

      if showIncomplete {
        Text("Answer every question in this part before continuing.")
          .font(theme.fonts.footnoteFont)
          .foregroundStyle(theme.palette.destructive.color)
          .padding(.horizontal, theme.spacing.md)
          .padding(.bottom, theme.spacing.sm)
      }
    }
  }

  private var progressBar: some View {
    // Answer progress only — not a cycle budget (DR-11).
    let total = max(session.caseFile.questions.count, 1)
    let fraction = CGFloat(session.answeredCount) / CGFloat(total)
    return GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(theme.palette.separator.color)
        Capsule()
          .fill(theme.palette.accent.color)
          .frame(width: max(geo.size.width * fraction, 0))
      }
    }
    .frame(height: 4)
  }

  private func questionCard(_ question: VerdictQuestion) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(question.prompt)
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)

      ForEach(question.options, id: \.self) { option in
        let selected = session.draftAnswers[question.id] == option
        Button {
          session.setAnswer(questionId: question.id, option: option)
        } label: {
          HStack {
            Text(PlayerFacingCopy.verdictOptionLabel(option))
              .font(theme.fonts.bodyFont)
              .foregroundStyle(
                selected
                  ? theme.palette.badgeText.color
                  : theme.palette.primaryText.color
              )
            Spacer()
          }
          .padding(theme.spacing.sm)
          .background(
            selected
              ? theme.palette.accent.color
              : theme.palette.elevatedBackground.color,
            in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
          )
          .overlay(
            RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
              .stroke(
                selected ? theme.palette.accent.color : theme.palette.separator.color,
                lineWidth: 1
              )
          )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityIdentifier("verdict-option-\(question.id)-\(option)")
        .accessibilityLabel(PlayerFacingCopy.verdictOptionLabel(option))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
      }
    }
    .padding(theme.spacing.md)
    .background(
      theme.palette.screenBackground.color,
      in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
    )
  }

  private var reviewBody: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        Text("Read this once more.")
          .font(theme.fonts.titleFont)
          .foregroundStyle(theme.palette.primaryText.color)

        Text(
          "These are the claims you are about to lock in. Wrong ones stay wrong."
        )
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

        ForEach(session.caseFile.questions, id: \.id) { question in
          VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(question.prompt)
              .font(theme.fonts.subheadlineFont)
              .foregroundStyle(theme.palette.secondaryText.color)
            Text(PlayerFacingCopy.verdictOptionLabel(session.draftAnswers[question.id] ?? "—"))
              .font(theme.fonts.headlineFont)
              .foregroundStyle(theme.palette.primaryText.color)
          }
          .padding(.vertical, theme.spacing.xs)
          .overlay(alignment: .bottom) {
            Rectangle()
              .fill(theme.palette.separator.color)
              .frame(height: 0.5)
          }
        }

        Button {
          phase = .confirm
        } label: {
          Text("I have read my answers")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.md)
            .background(
              theme.palette.accent.color,
              in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("verdict-review-continue")
        .padding(.top, theme.spacing.md)

        Button("Go back and change something") {
          phase = .sections
          sectionIndex = max(sections.count - 1, 0)
        }
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.accent.color)
      }
      .padding(theme.spacing.lg)
    }
  }

  private var confirmBody: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      Spacer()

      Text("File this.")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.destructive.color)

      Text(
        "You are saying you know what he did. If you are wrong about Ivy, about Thursday, about whether he is leaving — that is the story you chose."
      )
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.primaryText.color)

      Text("You cannot take a filed verdict back.")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)

      Button {
        let result = session.fileVerdict()
        switch result {
        case .filed:
          path = [.verdictResults]
        case .incomplete:
          showIncomplete = true
          phase = .sections
        }
      } label: {
        Text("File what I believe")
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.badgeText.color)
          .frame(maxWidth: .infinity)
          .padding(theme.spacing.md)
          .background(
            theme.palette.destructive.color,
            in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("verdict-file")
      .disabled(!session.allQuestionsAnswered)
      .opacity(session.allQuestionsAnswered ? 1 : 0.5)

      Button("Not yet") {
        phase = .review
      }
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.accent.color)

      Spacer()
    }
    .padding(theme.spacing.lg)
  }

  private func sectionComplete(_ questions: [VerdictQuestion]) -> Bool {
    questions.allSatisfy { q in
      guard let a = session.draftAnswers[q.id] else { return false }
      return !a.isEmpty
    }
  }

  private func goBack() {
    switch phase {
    case .intro:
      path = []
    case .sections:
      if sectionIndex > 0 {
        sectionIndex -= 1
      } else {
        phase = .intro
      }
    case .review:
      phase = .sections
      sectionIndex = max(sections.count - 1, 0)
    case .confirm:
      phase = .review
    }
  }

}
