// Sources/CarveUI/Views/LinkBoardView.swift
// Player-drawn connections. Entities come from carved fragment content only.

import SwiftUI
import CarveShell
import Accessibility

struct LinkBoardView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var selectedId: String?
  @State private var feedbackBanner: String?

  var body: some View {
    let entities = session.boardEntities
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        instructionBanner(entities: entities)

        if let feedbackBanner {
          feedbackToast(feedbackBanner)
        }

        if entities.isEmpty {
          emptyState
        } else if dynamicTypeSize.isAccessibilitySize {
          accessibleListCanvas(entities: entities)
          linkList(entities: entities)
        } else {
          boardCanvas(entities: entities)
          linkList(entities: entities)
        }
      }
    }
    .background(theme.palette.groupedBackground.color.ignoresSafeArea())
  }

  private func instructionBanner(entities: [BoardEntity]) -> some View {
    let selectedName = selectedEntityName(entities: entities)
    return VStack(alignment: .leading, spacing: 2) {
      Text("Suspicion Board")
        .font(theme.fonts.captionFont)
        .fontWeight(.bold)
        .foregroundStyle(theme.palette.tertiaryText.color)

      Text(
        selectedName == nil
          ? "Who belongs together? Tap a person, then who they connect to."
          : "Linking \(selectedName!) — tap another person to connect."
      )
      .font(theme.fonts.subheadlineFont)
      .fontWeight(.medium)
      .foregroundStyle(theme.palette.primaryText.color)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.elevatedBackground.color)
    .accessibilityIdentifier("links-instruction")
  }

  private func feedbackToast(_ text: String) -> some View {
    HStack(spacing: theme.spacing.xs) {
      Image(systemName: "link.circle.fill")
        .foregroundStyle(theme.palette.accent.color)
      Text(text)
        .font(theme.fonts.footnoteFont)
        .fontWeight(.semibold)
        .foregroundStyle(theme.palette.primaryText.color)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.xs)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.accent.color.opacity(0.15))
    .accessibilityIdentifier("links-feedback")
  }

  private var emptyState: some View {
    VStack(spacing: theme.spacing.md) {
      Spacer(minLength: 40)
      AppGlyph(appId: .board)
        .frame(width: 56, height: 56)
        .opacity(0.8)
      Text("No one on the board yet")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("People appear as you read the phone.")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .multilineTextAlignment(.center)
        .padding(.horizontal, theme.spacing.xl)
      Spacer(minLength: 40)
    }
    .frame(maxWidth: .infinity)
    .accessibilityIdentifier("links-empty")
  }

  private func boardCanvas(entities: [BoardEntity]) -> some View {
    GeometryReader { geo in
      let positions = nodePositions(count: entities.count, in: geo.size)
      ZStack {
        ForEach(edgeSegments(entities: entities, positions: positions), id: \.id) { edge in
          Path { path in
            path.move(to: edge.from)
            path.addLine(to: edge.to)
          }
          .stroke(
            theme.palette.accent.color,
            style: StrokeStyle(lineWidth: 2.5, dash: [6, 3])
          )
        }

        ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
          let point = index < positions.count ? positions[index] : .zero
          entityNode(entity, allEntities: entities)
            .position(point)
        }
      }
    }
    .frame(minHeight: 280)
    .padding(theme.spacing.md)
  }

  private func accessibleListCanvas(entities: [BoardEntity]) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      ForEach(entities) { entity in
        entityNode(entity, allEntities: entities)
      }
    }
    .padding(theme.spacing.md)
  }

  private func entityNode(_ entity: BoardEntity, allEntities: [BoardEntity]) -> some View {
    let isSelected = selectedId == entity.entityId
    let selectedName = selectedEntityName(entities: allEntities)

    return Button {
      tapEntity(entity.entityId, entities: allEntities)
    } label: {
      HStack(spacing: theme.spacing.xs) {
        ZStack {
          Circle()
            .fill(
              isSelected
                ? theme.palette.badgeText.color.opacity(0.3)
                : theme.palette.secondaryText.color.opacity(0.2)
            )
            .frame(width: 24, height: 24)
          Text(String(entity.displayName.prefix(1)).uppercased())
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(
              isSelected
                ? theme.palette.badgeText.color
                : theme.palette.primaryText.color
            )
        }

        Text(entity.displayName)
          .font(theme.fonts.footnoteFont)
          .fontWeight(.semibold)
          .lineLimit(1)
          .truncationMode(.tail)
          .foregroundStyle(
            isSelected
              ? theme.palette.badgeText.color
              : theme.palette.primaryText.color
          )

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.badgeText.color)
        }
      }
      .padding(.horizontal, theme.spacing.sm + 2)
      .padding(.vertical, theme.spacing.xs + 2)
      .background(
        isSelected
          ? theme.palette.accent.color
          : theme.palette.elevatedBackground.color,
        in: Capsule()
      )
      .scaleEffect(isSelected ? 1.05 : 1.0)
      .animation(.easeInOut(duration: 0.15), value: isSelected)
      .accessibilityIdentifier("link-entity-\(entity.entityId)")
      .accessibilityLabel(entity.displayName)
      .accessibilityHint(
        isSelected
          ? "Tap to deselect"
          : (selectedId == nil
            ? "Tap to select for linking"
            : "Tap to connect with \(selectedName ?? "selected person")")
      )
      .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
      .overlay(
        Capsule()
          .stroke(
            isSelected ? theme.palette.accent.color : theme.palette.separator.color,
            lineWidth: isSelected ? 2.5 : 1
          )
      )
    }
    .buttonStyle(.plain)
    .frame(minWidth: 44, minHeight: 44)
  }

  private func linkList(entities: [BoardEntity]) -> some View {
    let name: (String) -> String = { id in
      entities.first { $0.entityId == id }?.displayName ?? id
    }
    return VStack(alignment: .leading, spacing: theme.spacing.xs) {
      Text("Connected Pairs")
        .font(theme.fonts.captionFont)
        .fontWeight(.bold)
        .foregroundStyle(theme.palette.tertiaryText.color)
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.sm)

      if session.linkedPairs.isEmpty {
        Text("No connections created yet.")
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .padding(.horizontal, theme.spacing.md)
          .padding(.bottom, theme.spacing.md)
      } else {
        ForEach(Array(session.linkedPairs.sorted()), id: \.self) { key in
          let parts = key.split(separator: "|").map(String.init)
          if parts.count == 2 {
            HStack(spacing: theme.spacing.sm) {
              Image(systemName: "link")
                .font(theme.fonts.captionFont)
                .foregroundStyle(theme.palette.accent.color)
              Text("\(name(parts[0]))  —  \(name(parts[1]))")
                .font(theme.fonts.subheadlineFont)
                .fontWeight(.medium)
                .foregroundStyle(theme.palette.primaryText.color)
              Spacer()
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.xs + 2)
            .background(
              theme.palette.elevatedBackground.color,
              in: RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
            )
            .padding(.horizontal, theme.spacing.md)
            .accessibilityIdentifier("link-pair-\(key)")
            .accessibilityLabel("Connected \(name(parts[0])) to \(name(parts[1]))")
          }
        }
        .padding(.bottom, theme.spacing.md)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func tapEntity(_ id: String, entities: [BoardEntity]) {
    if let first = selectedId {
      if first == id {
        selectedId = nil
        return
      }
      let firstName = entities.first { $0.entityId == first }?.displayName ?? first
      let secondName = entities.first { $0.entityId == id }?.displayName ?? id

      session.link(first, id)
      selectedId = nil

      let toastText = "Linked \(firstName) & \(secondName)"
      feedbackBanner = toastText

      AccessibilityNotification.Announcement("Connected \(firstName) to \(secondName)").post()

      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        if feedbackBanner == toastText {
          feedbackBanner = nil
        }
      }
    } else {
      selectedId = id
    }
  }

  private func selectedEntityName(entities: [BoardEntity]) -> String? {
    guard let selectedId else { return nil }
    return entities.first { $0.entityId == selectedId }?.displayName ?? selectedId
  }

  private struct EdgeSegment: Identifiable {
    let id: String
    let from: CGPoint
    let to: CGPoint
  }

  private func edgeSegments(entities: [BoardEntity], positions: [CGPoint]) -> [EdgeSegment] {
    var edges: [EdgeSegment] = []
    for key in session.linkedPairs.sorted() {
      let parts = key.split(separator: "|").map(String.init)
      guard parts.count == 2,
        let i = entities.firstIndex(where: { $0.entityId == parts[0] }),
        let j = entities.firstIndex(where: { $0.entityId == parts[1] }),
        i < positions.count, j < positions.count
      else { continue }
      edges.append(EdgeSegment(id: key, from: positions[i], to: positions[j]))
    }
    return edges
  }

  private func nodePositions(count: Int, in size: CGSize) -> [CGPoint] {
    guard count > 0 else { return [] }
    if count == 1 {
      return [CGPoint(x: size.width / 2, y: size.height / 2)]
    }
    let radius = min(size.width, size.height) * 0.36
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    return (0..<count).map { i in
      let angle = (Double(i) / Double(count)) * 2 * Double.pi - Double.pi / 2
      return CGPoint(
        x: center.x + CGFloat(cos(angle)) * radius,
        y: center.y + CGFloat(sin(angle)) * radius)
    }
  }
}
