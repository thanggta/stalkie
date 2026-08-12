// Sources/CarveUI/Views/AppContainerView.swift
import SwiftUI
import CarveShell

struct AppContainerView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId
  @Binding var path: [PhoneRoute]

  var body: some View {
    VStack(spacing: 0) {
      // Status bar clearance — real phone apps draw under the status area.
      Spacer().frame(height: theme.statusBar.height)

      AppNavBar(
        title: appId.title,
        backLabel: "Home"
      ) {
        path = []
      }

      Group {
        switch appId {
        case .messages:
          MessagesListView(path: $path)
        case .notes:
          NotesListView(path: $path)
        case .phone:
          RecordListView(appId: .phone, path: $path)
        case .photos:
          PhotosGridView(path: $path)
        case .places:
          RecordListView(appId: .places, path: $path)
        case .board:
          LinkBoardView()
        case .decide:
          // Routed at home; keep a safe fallback.
          EmptyShellAppView(appId: appId)
        case .calendar, .camera, .browser, .mail, .settings, .music:
          EmptyShellAppView(appId: appId)
        }
      }
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
    .hideSystemNavigationChrome()
  }
}

/// iOS-style top bar: chevron + back label, centered title, hairline rule.
struct AppNavBar: View {
  @Environment(\.carveTheme) private var theme
  let title: String
  var backLabel: String = "Back"
  let onBack: () -> Void

  var body: some View {
    ZStack {
      Text(title)
        .font(theme.fonts.headlineFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)
        .lineLimit(1)

      HStack(spacing: theme.spacing.xxs) {
        Button(action: onBack) {
          HStack(spacing: 2) {
            Text("‹")
              .font(theme.fonts.titleFont)
              .fontWeight(.regular)
            Text(backLabel)
              .font(theme.fonts.bodyFont)
          }
          .foregroundStyle(theme.palette.accent.color)
        }
        .buttonStyle(.plain)
        Spacer(minLength: 0)
      }
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .frame(minHeight: 44)
    .background(theme.palette.elevatedBackground.color.opacity(0.94))
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(theme.palette.separator.color)
        .frame(height: 0.33)
    }
  }
}

struct EmptyShellAppView: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId

  var body: some View {
    VStack(spacing: theme.spacing.md) {
      Spacer()
      Text(appId.title)
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("Nothing here.")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.palette.groupedBackground.color)
  }
}

struct MessagesListView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  var body: some View {
    let items = session.visibleFragments(in: .messages)
    List {
      ForEach(items) { item in
        Button {
          path.append(.fragment(item.id))
        } label: {
          MessagesThreadRow(item: item, preview: threadPreview(item))
        }
        .listRowInsets(EdgeInsets(
          top: theme.spacing.sm,
          leading: theme.spacing.md,
          bottom: theme.spacing.sm,
          trailing: theme.spacing.md
        ))
        .listRowBackground(theme.palette.elevatedBackground.color)
        .listRowSeparatorTint(theme.palette.separator.color)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(theme.palette.elevatedBackground.color)
  }

  private func threadPreview(_ item: VisibleFragmentItem) -> String {
    if let content = try? FragmentContent.thread(item.fragment),
      let last = content.messages.last
    {
      return last.text
    }
    return item.fragment.label
  }
}

/// iMessage-style conversation row: avatar, name, preview, time — no chevron.
struct MessagesThreadRow: View {
  @Environment(\.carveTheme) private var theme
  let item: VisibleFragmentItem
  let preview: String

  var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      // Contact monogram — original, not a stock asset.
      ZStack {
        Circle()
          .fill(theme.palette.groupedBackground.color)
        Text(monogram)
          .font(theme.fonts.headlineFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.secondaryText.color)
      }
      .frame(width: 48, height: 48)

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline) {
          Text(rowTitle)
            .font(theme.fonts.headlineFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.primaryText.color)
            .lineLimit(1)
          Spacer(minLength: theme.spacing.sm)
          Text(timeLabel)
            .font(theme.fonts.footnoteFont)
            .foregroundStyle(theme.palette.tertiaryText.color)
        }
        HStack(spacing: theme.spacing.xs) {
          Text(preview)
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .lineLimit(2)
          if item.isUnreadUnlock {
            Circle()
              .fill(theme.palette.badge.color)
              .frame(width: 10, height: 10)
          }
        }
      }
    }
    .padding(.vertical, theme.spacing.xxs)
  }

  private var rowTitle: String {
    if let t = try? FragmentContent.thread(item.fragment) {
      return t.counterpartyDisplay
    }
    return item.fragment.label
  }

  private var monogram: String {
    let name = rowTitle
    let parts = name.split(separator: " ")
    if let first = parts.first?.first {
      return String(first).uppercased()
    }
    return "?"
  }

  private var timeLabel: String {
    guard let content = try? FragmentContent.thread(item.fragment),
      let last = content.messages.last
    else { return "" }
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime]
    guard let date = parser.date(from: last.at) else { return "" }
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
  }
}

struct NotesListView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  var body: some View {
    let items = session.visibleFragments(in: .notes)
    List {
      ForEach(items) { item in
        Button {
          path.append(.fragment(item.id))
        } label: {
          let title = (try? FragmentContent.note(item.fragment))?.title ?? item.fragment.label
          FragmentRow(item: item, subtitle: title)
        }
        .listRowBackground(
          item.isUnreadUnlock
            ? theme.palette.unlockBannerBackground.color.opacity(0.12)
            : theme.palette.elevatedBackground.color
        )
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }
}

struct RecordListView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId
  @Binding var path: [PhoneRoute]

  var body: some View {
    let items = session.visibleFragments(in: appId)
    List {
      ForEach(items) { item in
        Button {
          path.append(.fragment(item.id))
        } label: {
          FragmentRow(item: item, subtitle: item.fragment.label)
        }
        .listRowBackground(
          item.isUnreadUnlock
            ? theme.palette.unlockBannerBackground.color.opacity(0.12)
            : theme.palette.elevatedBackground.color
        )
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }
}

struct PhotosGridView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  private let columns = [
    GridItem(.flexible(), spacing: 2),
    GridItem(.flexible(), spacing: 2),
    GridItem(.flexible(), spacing: 2),
  ]

  var body: some View {
    let items = session.visibleFragments(in: .photos)
    ScrollView {
      if items.isEmpty {
        Text("No Photos")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .frame(maxWidth: .infinity)
          .padding(theme.spacing.xl)
      } else {
        LazyVGrid(columns: columns, spacing: 2) {
          ForEach(items) { item in
            Button {
              path.append(.fragment(item.id))
            } label: {
              ZStack(alignment: .topTrailing) {
                theme.palette.photoPlaceholder.color
                  .aspectRatio(1, contentMode: .fill)
                  .overlay {
                    Text("IMG")
                      .font(theme.fonts.captionFont)
                      .foregroundStyle(theme.palette.secondaryText.color)
                  }
                if item.isUnreadUnlock {
                  Circle()
                    .fill(theme.palette.badge.color)
                    .frame(width: 10, height: 10)
                    .padding(theme.spacing.xs)
                }
              }
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

struct FragmentRow: View {
  @Environment(\.carveTheme) private var theme
  let item: VisibleFragmentItem
  let subtitle: String

  var body: some View {
    HStack(spacing: theme.spacing.md) {
      VStack(alignment: .leading, spacing: theme.spacing.xxs) {
        HStack {
          Text(rowTitle)
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.primaryText.color)
          if item.isUnreadUnlock {
            Text("NEW")
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.badgeText.color)
              .padding(.horizontal, theme.spacing.xs)
              .padding(.vertical, theme.spacing.xxs)
              .background(
                theme.palette.badge.color,
                in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
              )
          }
        }
        Text(subtitle)
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .lineLimit(2)
      }
      Spacer()
      Text("›")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
    }
    .padding(.vertical, theme.spacing.xs)
  }

  private var rowTitle: String {
    switch item.fragment.type {
    case .thread:
      if let t = try? FragmentContent.thread(item.fragment) {
        return t.counterpartyDisplay
      }
      return item.fragment.label
    case .note:
      if let n = try? FragmentContent.note(item.fragment) {
        return n.title
      }
      return item.fragment.label
    default:
      return item.fragment.label
    }
  }
}
