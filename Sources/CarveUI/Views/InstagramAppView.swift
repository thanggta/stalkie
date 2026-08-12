// Sources/CarveUI/Views/InstagramAppView.swift
// Recognizable photo-social hierarchy from declarative surface content.
// Brand display name comes from PhoneAppLabels only.

import SwiftUI
import CarveCore
import CarveShell

struct InstagramAppView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]
  @State private var tab: Tab = .home

  private enum Tab: String, CaseIterable {
    case home, search, reels, shop, profile
  }

  private var items: [VisibleFragmentItem] {
    session.visibleFragments(in: .photoSocial)
  }

  private var profiles: [VisibleFragmentItem] {
    items.filter {
      $0.fragment.type == .record && $0.fragment.recordKind == "social_profile"
    }
  }

  private var posts: [VisibleFragmentItem] {
    items.filter { $0.fragment.type == .image }
  }

  private var dms: [VisibleFragmentItem] {
    items.filter { $0.fragment.type == .thread }
  }

  var body: some View {
    VStack(spacing: 0) {
      if items.isEmpty {
        emptyState
      } else {
        switch tab {
        case .home:
          feed
        case .profile:
          profileTab
        case .search, .reels, .shop:
          placeholderTab(tab)
        }
      }
      tabBar
    }
    .background(theme.palette.elevatedBackground.color)
  }

  private var emptyState: some View {
    VStack(spacing: theme.spacing.md) {
      Spacer()
      Text(PhoneAppLabels.title(for: .photoSocial))
        .font(theme.fonts.titleFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("No activity yet")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var feed: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        header
        if !profiles.isEmpty {
          storyRow
        }
        if posts.isEmpty && dms.isEmpty {
          Text("Follow people to see photos.")
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .padding(theme.spacing.lg)
        }
        ForEach(posts) { item in
          postCard(item)
        }
        if !dms.isEmpty {
          dmSection
        }
      }
    }
  }

  private var header: some View {
    HStack {
      Button {
        path = []
      } label: {
        Image(systemName: "chevron.left")
          .font(theme.fonts.bodyFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.primaryText.color)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Home")
      .accessibilityIdentifier("instagram-home")

      Text(PhoneAppLabels.title(for: .photoSocial))
        .font(theme.fonts.titleFont)
        .fontWeight(.bold)
        .foregroundStyle(theme.palette.primaryText.color)
        .accessibilityIdentifier("instagram-title")
      Spacer()
      if !dms.isEmpty {
        Button {
          if let first = dms.first {
            path.append(.fragment(first.id))
          }
        } label: {
          Image(systemName: "paperplane")
            .font(theme.fonts.titleFont)
            .foregroundStyle(theme.palette.primaryText.color)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("instagram-dms")
      }
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
  }

  private var storyRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: theme.spacing.md) {
        ForEach(profiles) { item in
          if let profile = try? FragmentContent.socialProfile(item.fragment) {
            Button {
              session.openFragment(item.id)
              path.append(.fragment(item.id))
            } label: {
              VStack(spacing: theme.spacing.xs) {
                ZStack {
                  Circle()
                    .strokeBorder(
                      AngularGradient(
                        colors: [
                          theme.palette.destructive.color,
                          theme.palette.iconPhotos.color,
                          theme.palette.iconNotes.color,
                          theme.palette.destructive.color,
                        ],
                        center: .center
                      ),
                      lineWidth: profile.hasStory ? 2.5 : 0
                    )
                    .frame(width: 68, height: 68)
                  Circle()
                    .fill(theme.palette.secondaryText.color.opacity(0.25))
                    .frame(width: 58, height: 58)
                  Text(String(profile.displayName.prefix(1)))
                    .font(theme.fonts.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.palette.badgeText.color)
                }
                Text(profile.handle)
                  .font(theme.fonts.captionFont)
                  .foregroundStyle(theme.palette.primaryText.color)
                  .lineLimit(1)
                  .frame(width: 72)
              }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("instagram-story-\(profile.handle)")
          }
        }
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm)
    }
  }

  private func postCard(_ item: VisibleFragmentItem) -> some View {
    let image = try? FragmentContent.image(item.fragment)
    return VStack(alignment: .leading, spacing: theme.spacing.sm) {
      HStack(spacing: theme.spacing.sm) {
        Circle()
          .fill(theme.palette.secondaryText.color.opacity(0.3))
          .frame(width: 32, height: 32)
        Text(image?.handle.map { "@\($0)" } ?? item.fragment.label)
          .font(theme.fonts.subheadlineFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.primaryText.color)
        Spacer()
      }
      .padding(.horizontal, theme.spacing.md)

      Button {
        path.append(.fragment(item.id))
      } label: {
        ZStack {
          theme.palette.photoPlaceholder.color
            .aspectRatio(1, contentMode: .fit)
          Image(systemName: "photo")
            .font(theme.fonts.font(36))
            .foregroundStyle(theme.palette.secondaryText.color)
          if item.isUnreadUnlock {
            VStack {
              HStack {
                Spacer()
                Circle()
                  .fill(theme.palette.badge.color)
                  .frame(width: 10, height: 10)
                  .padding(theme.spacing.sm)
              }
              Spacer()
            }
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("instagram-post-\(item.id)")

      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        if let likes = image?.likes {
          Text("\(likes) likes")
            .font(theme.fonts.subheadlineFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.primaryText.color)
        }
        if let caption = image?.caption, !caption.isEmpty {
          Text(caption)
            .font(theme.fonts.subheadlineFont)
            .foregroundStyle(theme.palette.primaryText.color)
        }
        if let comments = image?.comments, let first = comments.first {
          Text("\(first.from) \(first.text)")
            .font(theme.fonts.footnoteFont)
            .foregroundStyle(theme.palette.secondaryText.color)
            .lineLimit(2)
        }
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.bottom, theme.spacing.md)
    }
  }

  private var dmSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Messages")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
        .padding(theme.spacing.md)
      ForEach(dms) { item in
        Button {
          path.append(.fragment(item.id))
        } label: {
          let thread = try? FragmentContent.thread(item.fragment)
          HStack(spacing: theme.spacing.md) {
            Circle()
              .fill(theme.palette.secondaryText.color.opacity(0.3))
              .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
              Text(thread?.counterpartyDisplay ?? item.fragment.label)
                .font(theme.fonts.headlineFont)
                .foregroundStyle(theme.palette.primaryText.color)
              Text(thread?.messages.last?.text ?? "")
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("instagram-dm-\(item.id)")
      }
    }
  }

  private var profileTab: some View {
    ScrollView {
      if let item = profiles.first,
        let profile = try? FragmentContent.socialProfile(item.fragment)
      {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
          HStack(spacing: theme.spacing.lg) {
            ZStack {
              Circle()
                .strokeBorder(
                  profile.hasStory
                    ? theme.palette.iconPhotos.color
                    : theme.palette.separator.color,
                  lineWidth: 2)
                .frame(width: 86, height: 86)
              Circle()
                .fill(theme.palette.secondaryText.color.opacity(0.25))
                .frame(width: 76, height: 76)
              Text(String(profile.displayName.prefix(1)))
                .font(theme.fonts.titleFont)
                .fontWeight(.semibold)
                .foregroundStyle(theme.palette.badgeText.color)
            }
            Spacer()
            stat(profile.posts, "Posts")
            stat(profile.followers, "Followers")
            stat(profile.following, "Following")
            Spacer()
          }
          .padding(.horizontal, theme.spacing.md)

          VStack(alignment: .leading, spacing: 2) {
            Text(profile.displayName)
              .font(theme.fonts.headlineFont)
              .foregroundStyle(theme.palette.primaryText.color)
            Text("@\(profile.handle)")
              .font(theme.fonts.subheadlineFont)
              .foregroundStyle(theme.palette.secondaryText.color)
            if !profile.bio.isEmpty {
              Text(profile.bio)
                .font(theme.fonts.subheadlineFont)
                .foregroundStyle(theme.palette.primaryText.color)
                .padding(.top, theme.spacing.xs)
            }
          }
          .padding(.horizontal, theme.spacing.md)
          .onAppear { session.openFragment(item.id) }

          LazyVGrid(
            columns: [
              GridItem(.flexible(), spacing: 2),
              GridItem(.flexible(), spacing: 2),
              GridItem(.flexible(), spacing: 2),
            ],
            spacing: 2
          ) {
            ForEach(posts) { post in
              Button {
                path.append(.fragment(post.id))
              } label: {
                theme.palette.photoPlaceholder.color
                  .aspectRatio(1, contentMode: .fill)
                  .overlay {
                    Image(systemName: "photo")
                      .foregroundStyle(theme.palette.secondaryText.color)
                  }
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.top, theme.spacing.md)
      } else {
        Text("Profile unavailable")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .padding(theme.spacing.lg)
      }
    }
  }

  private func placeholderTab(_ tab: Tab) -> some View {
    VStack {
      Spacer()
      Text(tab.rawValue.capitalized)
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func stat(_ n: Int, _ label: String) -> some View {
    VStack(spacing: 2) {
      Text("\(n)")
        .font(theme.fonts.headlineFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)
      Text(label)
        .font(theme.fonts.captionFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private var tabBar: some View {
    HStack {
      tabButton(.home, "house")
      tabButton(.search, "magnifyingglass")
      tabButton(.reels, "play.rectangle")
      tabButton(.shop, "bag")
      tabButton(.profile, "person.circle")
    }
    .padding(.vertical, theme.spacing.sm)
    .overlay(alignment: .top) {
      Rectangle().fill(theme.palette.separator.color).frame(height: 0.33)
    }
  }

  private func tabButton(_ tab: Tab, _ system: String) -> some View {
    Button {
      self.tab = tab
    } label: {
      Image(systemName: self.tab == tab ? "\(system).fill" : system)
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.primaryText.color)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("instagram-tab-\(tab.rawValue)")
  }
}

struct InstagramProfileDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let profile = try? FragmentContent.socialProfile(fragment) {
      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
          HStack(spacing: theme.spacing.md) {
            Circle()
              .fill(theme.palette.secondaryText.color.opacity(0.3))
              .frame(width: 72, height: 72)
              .overlay {
                Text(String(profile.displayName.prefix(1)))
                  .font(theme.fonts.titleFont)
                  .foregroundStyle(theme.palette.badgeText.color)
              }
            VStack(alignment: .leading, spacing: 4) {
              Text(profile.displayName)
                .font(theme.fonts.titleFont)
                .foregroundStyle(theme.palette.primaryText.color)
              Text("@\(profile.handle)")
                .font(theme.fonts.subheadlineFont)
                .foregroundStyle(theme.palette.secondaryText.color)
            }
          }
          Text(profile.bio)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.primaryText.color)
          HStack(spacing: theme.spacing.lg) {
            Text("\(profile.posts) posts")
            Text("\(profile.followers) followers")
            Text("\(profile.following) following")
          }
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.secondaryText.color)
        }
        .padding(theme.spacing.lg)
      }
    } else {
      Text("Unreadable profile")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }
}
