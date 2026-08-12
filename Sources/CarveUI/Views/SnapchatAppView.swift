// Sources/CarveUI/Views/SnapchatAppView.swift
// Camera-first ephemeral chat surface. Brand name from PhoneAppLabels only.

import SwiftUI
import CarveCore
import CarveShell

struct SnapchatAppView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]
  @State private var showChats = false

  private var chats: [VisibleFragmentItem] {
    session.visibleFragments(in: .ephemeralChat)
  }

  var body: some View {
    ZStack {
      cameraLanding
      if showChats {
        chatDrawer
          .transition(.move(edge: .bottom))
      }
    }
    .animation(.easeOut(duration: 0.2), value: showChats)
  }

  private var cameraLanding: some View {
    ZStack {
      LinearGradient(
        colors: [
          theme.palette.primaryText.color,
          theme.palette.unlockBannerBackground.color,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack {
        HStack {
          Button {
            path = []
          } label: {
            Image(systemName: "chevron.left")
              .font(theme.fonts.bodyFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.badgeText.color)
              .frame(width: 36, height: 36)
              .background(theme.palette.elevatedBackground.color.opacity(0.2), in: Circle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Home")
          .accessibilityIdentifier("snapchat-home")
          Spacer()
          Text(PhoneAppLabels.title(for: .ephemeralChat))
            .font(theme.fonts.headlineFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.badgeText.color)
            .accessibilityIdentifier("snapchat-title")
          Spacer()
          Circle()
            .fill(theme.palette.elevatedBackground.color.opacity(0.2))
            .frame(width: 36, height: 36)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.sm)

        Spacer()

        // Shutter
        Circle()
          .strokeBorder(theme.palette.badgeText.color, lineWidth: 4)
          .frame(width: 72, height: 72)
          .overlay {
            Circle()
              .fill(theme.palette.badgeText.color.opacity(0.15))
              .padding(6)
          }
          .padding(.bottom, theme.spacing.lg)

        Button {
          showChats = true
        } label: {
          HStack(spacing: theme.spacing.xs) {
            Image(systemName: "message.fill")
            Text(chats.isEmpty ? "Chat" : "Chat (\(chats.count))")
          }
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.primaryText.color)
          .padding(.horizontal, theme.spacing.lg)
          .padding(.vertical, theme.spacing.sm)
          .background(
            theme.palette.iconNotes.color,
            in: Capsule()
          )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("snapchat-open-chats")
        .padding(.bottom, theme.spacing.xl)
      }
    }
  }

  private var chatDrawer: some View {
    VStack(spacing: 0) {
      Capsule()
        .fill(theme.palette.separator.color)
        .frame(width: 40, height: 4)
        .padding(.top, theme.spacing.sm)

      HStack {
        Text("Chat")
          .font(theme.fonts.titleFont)
          .fontWeight(.bold)
          .foregroundStyle(theme.palette.primaryText.color)
        Spacer()
        Button("Camera") {
          showChats = false
        }
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.accent.color)
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm)

      if chats.isEmpty {
        VStack(spacing: theme.spacing.sm) {
          Spacer()
          Text("No chats yet")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.primaryText.color)
          Text("Streaks and snaps appear here when available.")
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, theme.spacing.xl)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(chats) { item in
              Button {
                path.append(.fragment(item.id))
              } label: {
                chatRow(item)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("snapchat-chat-\(item.id)")

              Rectangle()
                .fill(theme.palette.separator.color)
                .frame(height: 0.33)
                .padding(.leading, 72)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.palette.elevatedBackground.color)
  }

  private func chatRow(_ item: VisibleFragmentItem) -> some View {
    let thread = try? FragmentContent.thread(item.fragment)
    return HStack(spacing: theme.spacing.md) {
      ZStack {
        Circle()
          .fill(theme.palette.iconNotes.color)
          .frame(width: 48, height: 48)
        Text(String((thread?.counterpartyDisplay ?? "?").prefix(1)))
          .font(theme.fonts.headlineFont)
          .fontWeight(.bold)
          .foregroundStyle(theme.palette.primaryText.color)
      }

      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text(thread?.counterpartyDisplay ?? item.fragment.label)
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.primaryText.color)
          if let streak = thread?.streakDays, streak > 0 {
            Text("🔥 \(streak)")
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.destructive.color)
          }
        }
        Text(preview(thread))
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .lineLimit(1)
      }
      Spacer()
      if item.isUnreadUnlock {
        Circle().fill(theme.palette.badge.color).frame(width: 8, height: 8)
      }
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
  }

  private func preview(_ thread: ThreadContent?) -> String {
    guard let last = thread?.messages.last else { return "Tap to open" }
    if last.ephemeral {
      let state = last.state ?? "delivered"
      return "Snap · \(state)"
    }
    return last.text
  }
}

struct SnapchatThreadDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let thread = try? FragmentContent.thread(fragment) {
      VStack(spacing: 0) {
        if let streak = thread.streakDays, streak > 0 {
          HStack {
            Text("🔥 \(streak) day streak")
              .font(theme.fonts.subheadlineFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.primaryText.color)
            Spacer()
          }
          .padding(.horizontal, theme.spacing.md)
          .padding(.vertical, theme.spacing.sm)
          .background(theme.palette.iconNotes.color.opacity(0.35))
        }

        ScrollView {
          VStack(alignment: .leading, spacing: theme.spacing.md) {
            ForEach(thread.messages) { message in
              snapBubble(message, thread: thread)
            }
          }
          .padding(theme.spacing.md)
        }
      }
      .background(theme.palette.groupedBackground.color)
    } else {
      Text("Chat unreadable")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private func snapBubble(_ message: ThreadMessage, thread: ThreadContent) -> some View {
    let outgoing = message.from == "eli"
    return HStack {
      if outgoing { Spacer(minLength: 40) }
      VStack(alignment: outgoing ? .trailing : .leading, spacing: 4) {
        if message.ephemeral {
          HStack(spacing: theme.spacing.xs) {
            Image(systemName: "square.fill")
              .font(theme.fonts.captionFont)
            Text(ephemeralLabel(message))
              .font(theme.fonts.subheadlineFont)
              .fontWeight(.semibold)
          }
          .foregroundStyle(
            outgoing
              ? theme.palette.badgeText.color
              : theme.palette.primaryText.color
          )
          .padding(.horizontal, theme.spacing.md)
          .padding(.vertical, theme.spacing.sm)
          .background(
            outgoing
              ? theme.palette.destructive.color
              : theme.palette.iconNotes.color,
            in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
          )
        } else {
          Text(message.text)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(
              outgoing
                ? theme.palette.badgeText.color
                : theme.palette.primaryText.color
            )
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(
              outgoing
                ? theme.palette.accent.color
                : theme.palette.elevatedBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
        }
        Text(thread.displayName(for: message.from))
          .font(theme.fonts.captionFont)
          .foregroundStyle(theme.palette.tertiaryText.color)
      }
      if !outgoing { Spacer(minLength: 40) }
    }
  }

  private func ephemeralLabel(_ message: ThreadMessage) -> String {
    let state = message.state ?? "delivered"
    switch state {
    case "opened": return "Opened"
    case "screenshot": return "Screenshot!"
    case "delivered": return "Received"
    default: return state.capitalized
    }
  }
}
