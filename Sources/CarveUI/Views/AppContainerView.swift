// Apps/Carve/Views/AppContainerView.swift
import SwiftUI
import CarveShell

struct AppContainerView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId
  @Binding var path: [PhoneRoute]

  var body: some View {
    VStack(spacing: 0) {
      AppNavBar(title: appId.title) {
        if path.count > 1 {
          path.removeLast()
        } else {
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
          RecordListView(appId: .places, path: $path)
        case .board:
          LinkBoardView()
        }
      }
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
  }
}

struct AppNavBar: View {
  @Environment(\.carveTheme) private var theme
  let title: String
  let onBack: () -> Void

  var body: some View {
    HStack {
      Button(action: onBack) {
        Text("‹ Home")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.accent.color)
      }
      Spacer()
      Text(title)
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Spacer()
      Text("‹ Home")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.accent.color.opacity(0))
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .background(theme.palette.elevatedBackground.color)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(theme.palette.separator.color)
        .frame(height: 0.5)
    }
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
          FragmentRow(item: item, subtitle: threadPreview(item))
        }
        .listRowBackground(rowBackground(item))
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  private func threadPreview(_ item: VisibleFragmentItem) -> String {
    if let content = try? FragmentContent.thread(item.fragment),
      let last = content.messages.last
    {
      return last.text
    }
    return item.fragment.label
  }

  private func rowBackground(_ item: VisibleFragmentItem) -> Color {
    item.isUnreadUnlock
      ? theme.palette.unlockBannerBackground.color.opacity(0.12)
      : theme.palette.elevatedBackground.color
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
    GridItem(.flexible(), spacing: 4),
    GridItem(.flexible(), spacing: 4),
    GridItem(.flexible(), spacing: 4),
  ]

  var body: some View {
    let items = session.visibleFragments(in: .photos)
    ScrollView {
      if items.isEmpty {
        Text("No photos recovered yet")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .padding(theme.spacing.xl)
      } else {
        LazyVGrid(columns: columns, spacing: 4) {
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
                  .clipShape(
                    RoundedRectangle(cornerRadius: theme.radii.card * 0.3, style: .continuous)
                  )
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
        .padding(theme.spacing.sm)
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
