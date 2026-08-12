// Sources/CarveUI/Views/ThreadDetailView.swift
import SwiftUI
import CarveCore
import CarveShell

struct ThreadDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let content = try? FragmentContent.thread(fragment) {
      VStack(spacing: 0) {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: theme.bubble.groupSpacing) {
            ForEach(Array(content.messages.enumerated()), id: \.element.id) { index, message in
              let isOutgoing = message.from == "eli"
              let prevOutgoing: Bool? = index > 0
                ? content.messages[index - 1].from == "eli"
                : nil
              MessageBubble(
                message: message,
                isOutgoing: isOutgoing,
                showTail: prevOutgoing != isOutgoing,
                timeLabel: shouldShowTime(index: index, messages: content.messages)
                  ? formatTime(message.at) : nil
              )
            }
          }
          .padding(.horizontal, theme.spacing.md)
          .padding(.vertical, theme.spacing.md)
        }

        composerBar
      }
      .background(theme.palette.screenBackground.color)
    } else {
      Text("Unreadable thread")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private var composerBar: some View {
    HStack(alignment: .center, spacing: theme.spacing.sm) {
      Image(systemName: "plus.circle.fill")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
        .opacity(0.55)

      HStack {
        Text("iMessage")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.tertiaryText.color)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm + 2)
      .background(
        Capsule()
          .stroke(theme.palette.separator.color, lineWidth: 1)
      )

      Image(systemName: "waveform.circle.fill")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
        .opacity(0.55)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .background(theme.palette.elevatedBackground.color)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(theme.palette.separator.color)
        .frame(height: 0.33)
    }
  }

  private func shouldShowTime(index: Int, messages: [ThreadMessage]) -> Bool {
    // Only stamp the last bubble in a consecutive same-sender run (iMessage pacing).
    if index == messages.count - 1 { return true }
    return messages[index].from != messages[index + 1].from
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
  var showTail: Bool = true
  var timeLabel: String?

  var body: some View {
    HStack(alignment: .bottom, spacing: 0) {
      if isOutgoing {
        Spacer(minLength: theme.spacing.xxl)
      }
      VStack(alignment: isOutgoing ? .trailing : .leading, spacing: theme.bubble.stackSpacing) {
        bubbleBody
        if let timeLabel {
          Text(timeLabel)
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
            .padding(.horizontal, 4)
        }
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
      in: BubbleShape(
        isOutgoing: isOutgoing,
        radius: theme.radii.bubble,
        tail: showTail ? theme.radii.bubbleTail : theme.radii.bubble
      )
    )
  }
}

/// Continuous bubble with a softened corner on the tail side.
struct BubbleShape: Shape {
  var isOutgoing: Bool
  var radius: Double
  var tail: Double

  func path(in rect: CGRect) -> Path {
    let r = min(CGFloat(radius), min(rect.width, rect.height) / 2)
    let t = min(CGFloat(tail), r)
    let tl = r
    let tr = r
    let bl = isOutgoing ? r : t
    let br = isOutgoing ? t : r

    var p = Path()
    p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
    p.addArc(
      center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
      radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
    p.addArc(
      center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
      radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
    p.addArc(
      center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
      radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
    p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
    p.addArc(
      center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
      radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
    p.closeSubpath()
    return p
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
