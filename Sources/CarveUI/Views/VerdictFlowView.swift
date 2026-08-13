// Sources/CarveUI/Views/VerdictFlowView.swift
// Forced complete filing (DR-11). Progress is pacing, not a resource bar.

import SwiftUI
import CarveCore
import CarveShell
import Accessibility

struct VerdictFlowView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Binding var path: [PhoneRoute]

  @State private var phase: Phase = .intro
  @State private var questionIndex: Int = 0
  @State private var showIncomplete = false

  private enum Phase: Equatable {
    case intro
    case questions
    case review
    case confirm
  }

  private var questions: [VerdictQuestion] {
    session.caseFile.questions
  }

  private func partTitle(for index: Int) -> (part: Int, totalParts: Int, title: String) {
    let total = max(questions.count, 1)
    if index < total / 3 {
      return (1, 3, "What happened")
    } else if index < (total * 2) / 3 {
      return (2, 3, "Who they are to each other")
    } else {
      return (3, 3, "What you are going to believe")
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      AppNavBar(title: navTitle, backLabel: backLabelForPhase) {
        goBack()
      }

      switch phase {
      case .intro:
        introBody
      case .questions:
        questionBody
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

  private var backLabelForPhase: String {
    phase == .intro ? "Home" : "Back"
  }

  private var navTitle: String {
    switch phase {
    case .intro: return "Decide"
    case .questions:
      return "\(questionIndex + 1) of \(questions.count)"
    case .review: return "Review"
    case .confirm: return "File"
    }
  }

  private var introBody: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        Text("You are about to accuse someone.")
          .font(theme.fonts.largeTitleFont)
          .fontWeight(.bold)
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
          phase = .questions
          questionIndex = 0
        } label: {
          Text("I am ready to answer")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity, minHeight: 50)
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

  private var questionBody: some View {
    guard !questions.isEmpty else {
      return AnyView(
        Text("No questions in case")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
      )
    }

    let safeIndex = min(max(questionIndex, 0), questions.count - 1)
    let currentQuestion = questions[safeIndex]
    let partInfo = partTitle(for: safeIndex)

    return AnyView(
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          HStack {
            Text("Part \(partInfo.part) of \(partInfo.totalParts)")
              .font(theme.fonts.captionFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.tertiaryText.color)
            Spacer()
            Text("\(session.answeredCount)/\(questions.count) answered")
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.secondaryText.color)
          }
          Text(partInfo.title)
            .font(theme.fonts.subheadlineFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.primaryText.color)
          progressBar
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.palette.elevatedBackground.color)

        ScrollView {
          VStack(alignment: .leading, spacing: theme.spacing.lg) {
            singleQuestionCard(currentQuestion)
          }
          .padding(theme.spacing.md)
        }

        if showIncomplete {
          Text("Please select an answer before moving forward.")
            .font(theme.fonts.footnoteFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.destructive.color)
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.xs)
            .accessibilityIdentifier("verdict-incomplete-warning")
        }

        HStack(spacing: theme.spacing.md) {
          if safeIndex > 0 {
            Button {
              showIncomplete = false
              questionIndex = safeIndex - 1
              AccessibilityNotification.Announcement("Question \(questionIndex + 1)").post()
            } label: {
              HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Previous")
              }
              .font(theme.fonts.bodyFont)
              .foregroundStyle(theme.palette.accent.color)
              .frame(minWidth: 88, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("verdict-prev")
          }

          Spacer()

          Button {
            let hasAnswer = session.draftAnswers[currentQuestion.id] != nil
            if hasAnswer {
              showIncomplete = false
              if safeIndex + 1 >= questions.count {
                phase = .review
              } else {
                questionIndex = safeIndex + 1
                AccessibilityNotification.Announcement("Question \(questionIndex + 1)").post()
              }
            } else {
              showIncomplete = true
            }
          } label: {
            HStack(spacing: 4) {
              Text(safeIndex + 1 >= questions.count ? "Review Claims" : "Next")
              if safeIndex + 1 < questions.count {
                Image(systemName: "chevron.right")
              }
            }
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .padding(.horizontal, theme.spacing.md)
            .frame(minHeight: 44)
            .background(
              theme.palette.accent.color,
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("verdict-next")
        }
        .padding(theme.spacing.md)
        .background(theme.palette.elevatedBackground.color)
      }
    )
  }

  private var progressBar: some View {
    let total = max(questions.count, 1)
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

  private func singleQuestionCard(_ question: VerdictQuestion) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text(question.prompt)
        .font(theme.fonts.titleFont)
        .fontWeight(.bold)
        .foregroundStyle(theme.palette.primaryText.color)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)

      VStack(spacing: theme.spacing.sm) {
        ForEach(question.options, id: \.self) { option in
          let selected = session.draftAnswers[question.id] == option
          Button {
            showIncomplete = false
            session.setAnswer(questionId: question.id, option: option)
          } label: {
            HStack(spacing: theme.spacing.sm) {
              Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(theme.fonts.bodyFont)
                .foregroundStyle(
                  selected
                    ? theme.palette.badgeText.color
                    : theme.palette.secondaryText.color
                )

              Text(displayOption(option))
                .font(theme.fonts.bodyFont)
                .fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(
                  selected
                    ? theme.palette.badgeText.color
                    : theme.palette.primaryText.color
                )
                .multilineTextAlignment(.leading)
              Spacer()
            }
            .padding(theme.spacing.md)
            .background(
              selected
                ? theme.palette.accent.color
                : theme.palette.elevatedBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
            .scaleEffect(selected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: selected)
            .overlay(
              RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
                .stroke(
                  selected ? theme.palette.accent.color : theme.palette.separator.color,
                  lineWidth: selected ? 2 : 1
                )
            )
          }
          .buttonStyle(.plain)
          .frame(minHeight: 48)
          .accessibilityIdentifier("verdict-option-\(question.id)-\(option)")
          .accessibilityLabel(displayOption(option))
          .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        }
      }
    }
    .padding(theme.spacing.lg)
    .background(
      theme.palette.screenBackground.color,
      in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
    )
  }

  private var reviewBody: some View {
    let unansweredCount = questions.count - session.answeredCount
    return ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        Text("Read your claims once more.")
          .font(theme.fonts.titleFont)
          .fontWeight(.bold)
          .foregroundStyle(theme.palette.primaryText.color)
          .accessibilityAddTraits(.isHeader)

        Text(
          "These are the 15 claims you are about to lock in. Tap any item to change your answer."
        )
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)

        if unansweredCount > 0 {
          Text("\(unansweredCount) question\(unansweredCount == 1 ? "" : "s") unanswered")
            .font(theme.fonts.footnoteFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.destructive.color)
            .padding(.top, theme.spacing.xs)
        }

        ForEach(Array(questions.enumerated()), id: \.element.id) { idx, question in
          let answer = session.draftAnswers[question.id]
          Button {
            questionIndex = idx
            phase = .questions
          } label: {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("\(idx + 1). \(question.prompt)")
                  .font(theme.fonts.subheadlineFont)
                  .foregroundStyle(theme.palette.secondaryText.color)
                  .multilineTextAlignment(.leading)

                if let answer, !answer.isEmpty {
                  Text(displayOption(answer))
                    .font(theme.fonts.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.palette.primaryText.color)
                } else {
                  Text("Unanswered")
                    .font(theme.fonts.footnoteFont)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.palette.destructive.color)
                }
              }
              Spacer()
              Image(systemName: "pencil")
                .font(theme.fonts.subheadlineFont)
                .foregroundStyle(theme.palette.accent.color)
            }
            .padding(theme.spacing.sm)
            .background(
              theme.palette.elevatedBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("verdict-review-item-\(question.id)")
        }

        Button {
          if session.allQuestionsAnswered {
            showIncomplete = false
            phase = .confirm
          } else {
            showIncomplete = true
            if let firstUnanswered = questions.firstIndex(where: { session.draftAnswers[$0.id] == nil }) {
              questionIndex = firstUnanswered
              phase = .questions
            }
          }
        } label: {
          Text(session.allQuestionsAnswered ? "Lock in answers" : "Complete remaining questions")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
              session.allQuestionsAnswered ? theme.palette.accent.color : theme.palette.destructive.color,
              in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("verdict-review-continue")
        .padding(.top, theme.spacing.md)

        Button("Go back to questions") {
          phase = .questions
          questionIndex = max(questions.count - 1, 0)
        }
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.accent.color)
        .frame(minHeight: 44)
      }
      .padding(theme.spacing.lg)
    }
  }

  private var confirmBody: some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      Spacer()

      Text("This is the line.")
        .font(theme.fonts.largeTitleFont)
        .fontWeight(.bold)
        .foregroundStyle(theme.palette.destructive.color)
        .accessibilityAddTraits(.isHeader)

      Text(
        "You are saying you know what he did. If you are wrong about Ivy, about Thursday, about whether he is leaving — that is the story you chose."
      )
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.primaryText.color)

      Text(
        "\(questions.count) answers. Wrong ones stay wrong. You cannot take a filed verdict back."
      )
      .font(theme.fonts.headlineFont)
      .foregroundStyle(theme.palette.secondaryText.color)

      Button {
        let result = session.fileVerdict()
        switch result {
        case .filed:
          path = [.verdictResults]
        case .incomplete:
          showIncomplete = true
          phase = .questions
          if let firstUnanswered = questions.firstIndex(where: { session.draftAnswers[$0.id] == nil }) {
            questionIndex = firstUnanswered
          }
        }
      } label: {
        Text("File what I believe")
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.badgeText.color)
          .frame(maxWidth: .infinity, minHeight: 52)
          .background(
            theme.palette.destructive.color,
            in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("verdict-file")
      .accessibilityHint("Locks your answers permanently for this playthrough")
      .disabled(!session.allQuestionsAnswered)
      .opacity(session.allQuestionsAnswered ? 1 : 0.5)

      Button("Not yet — review claims") {
        phase = .review
      }
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.accent.color)
      .frame(minHeight: 44)

      Spacer()
    }
    .padding(theme.spacing.lg)
  }

  private func goBack() {
    switch phase {
    case .intro:
      path = []
    case .questions:
      if questionIndex > 0 {
        questionIndex -= 1
      } else {
        phase = .intro
      }
    case .review:
      phase = .questions
      questionIndex = max(questions.count - 1, 0)
    case .confirm:
      phase = .review
    }
  }

  private func displayOption(_ raw: String) -> String {
    raw
      .split(separator: "_")
      .map { part in
        guard let first = part.first else { return String(part) }
        return String(first).uppercased() + part.dropFirst()
      }
      .joined(separator: " ")
  }
}
