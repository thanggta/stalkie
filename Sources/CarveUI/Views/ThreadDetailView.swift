// Sources/CarveUI/Views/ThreadDetailView.swift
import SwiftUI
import CarveCore
import CarveShell

struct ThreadDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let content = try? FragmentContent.thread(fragment) {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: theme.bubble.groupSpacing) {
          ForEach(content.messages) { message in
            MessageBubble(
              message: message,
              isOutgoing: message.from == "eli",
              timeLabel: formatTime(message.at)
            )
          }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.md)
      }
      .background(theme.palette.screenBackground.color)
    } else {
      Text("Unreadable thread")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private func formatTime(_ iso: String) -> String {
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime]
    if let date = parser.date(from: iso) {
      let f = DateFormatter()
      f.dateFormat = "h:mm a"
      return f.string(from: date)
    }
    return String(iso.prefix(16))
  }
}

struct MessageBubble: View {
  @Environment(\.carveTheme) private var theme
  let message: ThreadMessage
  let isOutgoing: Bool
  let timeLabel: String

  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if isOutgoing {
        Spacer(minLength: theme.spacing.xxl)
      }
      VStack(alignment: isOutgoing ? .trailing : .leading, spacing: theme.bubble.stackSpacing) {
        bubbleBody
        Text(timeLabel)
          .font(theme.fonts.captionFont)
          .foregroundStyle(theme.palette.tertiaryText.color)
      }
      .layoutPriority(1)
      if !isOutgoing {
        Spacer(minLength: theme.spacing.xxl)
      }
    }
  }

  private var bubbleBody: some View {
    Group {
      if message.corrupt {
        CorruptTextView(text: message.text)
      } else {
        Text(message.text)
          .font(theme.fonts.bubbleFont)
          .foregroundStyle(
            isOutgoing
              ? theme.palette.outgoingBubbleText.color
              : theme.palette.incomingBubbleText.color
          )
      }
    }
    .padding(.horizontal, theme.bubble.horizontalPadding)
    .padding(.vertical, theme.bubble.verticalPadding)
    .background(
      isOutgoing
        ? theme.palette.outgoingBubble.color
        : theme.palette.incomingBubble.color,
      in: RoundedRectangle(
        cornerRadius: theme.radii.bubble * (1 - theme.bubble.squareness * 0.7),
        style: .continuous
      )
    )
    // maxWidthFraction is enforced by the sibling Spacer minLength in the parent HStack
    // (≈ 1 - fraction of row width), not a hardcoded point size.
  }
}

/// Renders authored █ spans with unrecovered styling. Does not invent corruption.
struct CorruptTextView: View {
  @Environment(\.carveTheme) private var theme
  let text: String

  var body: some View {
    Text(attributed)
      .font(theme.fonts.bubbleFont)
  }

  private var attributed: AttributedString {
    var result = AttributedString()
    for ch in text {
      var piece = AttributedString(String(ch))
      if ch == "█" || ch == "▆" || ch == "▇" {
        piece.foregroundColor = theme.palette.corruptGlyph.color
      } else {
        piece.foregroundColor = theme.palette.incomingBubbleText.color
      }
      result.append(piece)
    }
    return result
  }
}
