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
      // Messages / camera-first Snapchat own their chrome; Instagram has its own header.
      if showsCompactNav {
        AppNavBar(title: appId.title, backLabel: "Home") {
          path = []
        }
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
          MapsAppView(path: $path)
        case .photoSocial:
          InstagramAppView(path: $path)
        case .ephemeralChat:
          SnapchatAppView(path: $path)
        case .board:
          LinkBoardView()
        case .decide:
          EmptyShellAppView(appId: appId)
        case .calendar, .camera, .browser, .mail, .settings, .music, .clock, .reminders,
          .weather, .facetime, .appstore, .health, .wallet, .files, .books,
          .podcasts, .tv, .homekit, .contacts, .calculator, .stocks:
          EmptyShellAppView(appId: appId)
        }
      }
    }
    .background(
      (appId == .messages || appId == .photoSocial || appId == .ephemeralChat
        ? theme.palette.elevatedBackground.color
        : theme.palette.groupedBackground.color)
        .ignoresSafeArea()
    )
    .hideSystemNavigationChrome()
  }

  private var showsCompactNav: Bool {
    switch appId {
    case .messages, .photoSocial, .ephemeralChat:
      return false
    default:
      return true
    }
  }
}

/// iOS-style compact top bar: chevron + back label, centered title.
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
        .accessibilityAddTraits(.isHeader)
        .padding(.horizontal, 88)

      HStack(spacing: theme.spacing.xxs) {
        Button(action: onBack) {
          HStack(spacing: 3) {
            Image(systemName: "chevron.left")
              .font(theme.fonts.bodyFont)
              .fontWeight(.semibold)
            Text(backLabel)
              .font(theme.fonts.bodyFont)
          }
          .foregroundStyle(theme.palette.accent.color)
          .frame(minWidth: 64, minHeight: 44, alignment: .leading)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(backLabel)")
        .accessibilityIdentifier(backLabel == "Home" ? "nav-home" : "nav-back")
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
      AppGlyph(appId: appId)
        .frame(width: theme.icon.size, height: theme.icon.size)
        .opacity(0.9)
      Text(appId.title)
        .font(theme.fonts.titleFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)
      Text(emptyCopy)
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .multilineTextAlignment(.center)
        .padding(.horizontal, theme.spacing.xl)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.palette.groupedBackground.color)
  }

  private var emptyCopy: String {
    switch appId {
    case .calendar: return "No Events"
    case .mail: return "No Mail"
    case .browser: return "No tabs open"
    case .settings: return ""
    case .camera: return "Camera unavailable"
    case .contacts: return "No Contacts"
    case .reminders: return "No Reminders"
    default: return "No content"
    }
  }
}

// MARK: - Messages (large-title chrome)

struct MessagesListView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]
  @State private var query: String = ""

  private var items: [VisibleFragmentItem] {
    let all = session.visibleFragments(in: .messages)
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return all }
    return all.filter {
      rowTitle($0).localizedCaseInsensitiveContains(q)
        || threadPreview($0).localizedCaseInsensitiveContains(q)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      messagesTopBar

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Messages")
            .font(theme.fonts.largeTitleFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.primaryText.color)
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.xxs)
            .padding(.bottom, theme.spacing.sm)

          searchField
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, theme.spacing.sm)

          LazyVStack(spacing: 0) {
            ForEach(items) { item in
              Button {
                path.append(.fragment(item.id))
              } label: {
                MessagesThreadRow(item: item, preview: threadPreview(item))
                  .padding(.horizontal, theme.spacing.md)
                  .padding(.vertical, theme.spacing.sm + 2)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("messages-thread-\(item.id)")

              Rectangle()
                .fill(theme.palette.separator.color)
                .frame(height: 0.33)
                .padding(.leading, theme.spacing.md + 56 + theme.spacing.md)
            }
          }
        }
      }
    }
    .background(theme.palette.elevatedBackground.color)
  }

  private var messagesTopBar: some View {
    HStack {
      Button {
        path = []
      } label: {
        HStack(spacing: 3) {
          Image(systemName: "chevron.left")
            .font(theme.fonts.bodyFont)
            .fontWeight(.semibold)
          Text("Home")
            .font(theme.fonts.bodyFont)
        }
        .foregroundStyle(theme.palette.accent.color)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Home")
      .accessibilityIdentifier("nav-home")

      Spacer()

      Image(systemName: "square.and.pencil")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.accent.color.opacity(0.35))
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.xs)
    .frame(minHeight: 44)
  }

  private var searchField: some View {
    HStack(spacing: theme.spacing.xs) {
      Image(systemName: "magnifyingglass")
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
      TextField(
        "",
        text: $query,
        prompt: Text("Search")
          .foregroundStyle(theme.palette.tertiaryText.color)
      )
      .font(theme.fonts.bodyFont)
      .foregroundStyle(theme.palette.primaryText.color)
    }
    .padding(.horizontal, theme.spacing.sm + 2)
    .padding(.vertical, theme.spacing.sm)
    .background(
      theme.palette.groupedBackground.color,
      in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
    )
  }

  private func threadPreview(_ item: VisibleFragmentItem) -> String {
    if let content = try? FragmentContent.thread(item.fragment),
      let last = content.messages.last
    {
      return last.text
    }
    return item.fragment.label
  }

  private func rowTitle(_ item: VisibleFragmentItem) -> String {
    if let t = try? FragmentContent.thread(item.fragment) {
      return t.counterpartyDisplay(ownerEntityId: session.caseFile.ownerEntityId)
    }
    return item.fragment.label
  }
}

/// iMessage-style conversation row: avatar, name, preview, time.
struct MessagesThreadRow: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let item: VisibleFragmentItem
  let preview: String

  var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      // Contact monogram avatar
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [
                theme.palette.secondaryText.color.opacity(0.35),
                theme.palette.tertiaryText.color.opacity(0.55),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
        Text(monogram)
          .font(theme.fonts.headlineFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.badgeText.color)
      }
      .frame(width: 52, height: 52)

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
          Image(systemName: "chevron.right")
            .font(theme.fonts.captionFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.tertiaryText.color.opacity(0.55))
        }
        HStack(alignment: .center, spacing: theme.spacing.xs) {
          Text(preview)
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          if item.isUnreadUnlock {
            Circle()
              .fill(theme.palette.badge.color)
              .frame(width: 10, height: 10)
          }
        }
      }
    }
    .contentShape(Rectangle())
  }

  private var rowTitle: String {
    if let t = try? FragmentContent.thread(item.fragment) {
      return t.counterpartyDisplay(ownerEntityId: session.caseFile.ownerEntityId)
    }
    return item.fragment.label
  }

  private var monogram: String {
    let parts = rowTitle.split(separator: " ")
    if parts.count >= 2, let a = parts[0].first, let b = parts[1].first {
      return "\(a)\(b)".uppercased()
    }
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

// MARK: - Notes / Records / Photos

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
          let note = try? FragmentContent.note(item.fragment)
          let title = note?.title ?? item.fragment.label
          // Preview = first line of body when it differs from the title.
          let preview: String = {
            guard let body = note?.body else { return title }
            let line = body.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
              .first.map(String.init) ?? body
            return line == title ? "" : line
          }()
          FragmentRow(item: item, subtitle: preview)
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
                    Image(systemName: "photo")
                      .font(theme.fonts.titleFont)
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
            .accessibilityIdentifier("photos-item-\(item.id)")
            .accessibilityLabel(item.fragment.label)
            .accessibilityHint(item.isUnreadUnlock ? "New" : "")
          }
        }
      }
    }
  }
}

struct FragmentRow: View {
  @EnvironmentObject private var session: GameSession
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
      Image(systemName: "chevron.right")
        .font(theme.fonts.captionFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.tertiaryText.color.opacity(0.6))
    }
    .padding(.vertical, theme.spacing.xs)
  }

  private var rowTitle: String {
    switch item.fragment.type {
    case .thread:
      if let t = try? FragmentContent.thread(item.fragment) {
        return t.counterpartyDisplay(ownerEntityId: session.caseFile.ownerEntityId)
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
