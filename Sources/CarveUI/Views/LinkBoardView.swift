// Sources/CarveUI/Views/LinkBoardView.swift
// Player-drawn connections. Entities come from carved fragment content only.

import SwiftUI
import CarveShell

struct LinkBoardView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @State private var selectedId: String?

  var body: some View {
    let entities = session.boardEntities
    VStack(alignment: .leading, spacing: 0) {
      instructionBanner

      if entities.isEmpty {
        emptyState
      } else {
        boardCanvas(entities: entities)
        linkList(entities: entities)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private var instructionBanner: some View {
    Text(
      selectedId == nil
        ? "Tap two names to connect them. What belongs together?"
        : "Now tap who that connects to."
    )
    .font(theme.fonts.subheadlineFont)
    .foregroundStyle(theme.palette.secondaryText.color)
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.elevatedBackground.color)
  }

  private var emptyState: some View {
    VStack(spacing: theme.spacing.md) {
      Spacer()
      Text("Nothing on the board yet")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("Open messages, calls, and photos. People you find will show up here.")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .multilineTextAlignment(.center)
        .padding(.horizontal, theme.spacing.xl)
      Spacer()
    }
    .frame(maxWidth: .infinity)
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
          .stroke(theme.palette.accent.color, lineWidth: 2)
        }

        ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
          let point = index < positions.count ? positions[index] : .zero
          entityNode(entity)
            .position(point)
        }
      }
    }
    .frame(minHeight: 280)
    .padding(theme.spacing.md)
  }

  private func entityNode(_ entity: BoardEntity) -> some View {
    let isSelected = selectedId == entity.entityId
    return Button {
      tapEntity(entity.entityId)
    } label: {
      Text(entity.displayName)
        .font(theme.fonts.footnoteFont)
        .foregroundStyle(
          isSelected
            ? theme.palette.badgeText.color
            : theme.palette.primaryText.color
        )
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(
          isSelected
            ? theme.palette.accent.color
            : theme.palette.elevatedBackground.color,
          in: Capsule()
        )
        .accessibilityIdentifier("link-entity-\(entity.entityId)")
        .overlay(
          Capsule()
            .stroke(
              isSelected ? theme.palette.accent.color : theme.palette.separator.color,
              lineWidth: 1
            )
        )
    }
    .buttonStyle(.plain)
  }

  private func linkList(entities: [BoardEntity]) -> some View {
    let name: (String) -> String = { id in
      entities.first { $0.entityId == id }?.displayName ?? id
    }
    return VStack(alignment: .leading, spacing: theme.spacing.xs) {
      Text("Connections")
        .font(theme.fonts.captionFont)
        .foregroundStyle(theme.palette.tertiaryText.color)
        .padding(.horizontal, theme.spacing.md)

      if session.linkedPairs.isEmpty {
        Text("None yet.")
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.secondaryText.color)
          .padding(.horizontal, theme.spacing.md)
          .padding(.bottom, theme.spacing.md)
      } else {
        ForEach(Array(session.linkedPairs.sorted()), id: \.self) { key in
          let parts = key.split(separator: "|").map(String.init)
          if parts.count == 2 {
            Text("\(name(parts[0]))  —  \(name(parts[1]))")
              .font(theme.fonts.subheadlineFont)
              .foregroundStyle(theme.palette.primaryText.color)
              .padding(.horizontal, theme.spacing.md)
              .padding(.vertical, theme.spacing.xs)
          }
        }
        .padding(.bottom, theme.spacing.md)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.palette.groupedBackground.color)
  }

  private func tapEntity(_ id: String) {
    if let first = selectedId {
      if first == id {
        selectedId = nil
        return
      }
      session.link(first, id)
      selectedId = nil
    } else {
      selectedId = id
    }
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
