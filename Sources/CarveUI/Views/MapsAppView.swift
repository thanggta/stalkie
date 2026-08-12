// Sources/CarveUI/Views/MapsAppView.swift
// Google Maps-style location history from authored data only.
// No device location, no network, no real residential addresses.

import SwiftUI
import CarveCore
import CarveShell

struct MapsAppView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]
  @State private var selectedVisitId: String?

  private var items: [VisibleFragmentItem] {
    session.visibleFragments(in: .places)
  }

  private var timeline: LocationTimeline? {
    guard let first = items.first else { return nil }
    return try? FragmentContent.locationTimeline(first.fragment)
  }

  var body: some View {
    if items.isEmpty {
      emptyState
    } else if let timeline {
      VStack(spacing: 0) {
        mapCanvas(timeline)
          .frame(maxHeight: .infinity)
        visitList(timeline)
          .frame(maxHeight: 280)
      }
      .onAppear {
        for item in items where !item.isCarved {
          session.openFragment(item.id)
        }
        if selectedVisitId == nil {
          selectedVisitId = timeline.visits.first?.id
        }
      }
    } else {
      Text("Location history unreadable")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var emptyState: some View {
    VStack(spacing: theme.spacing.md) {
      Spacer()
      Image(systemName: "map")
        .font(theme.fonts.font(40))
        .foregroundStyle(theme.palette.iconPlaces.color)
      Text("No recent places")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("Timeline appears when location history is available on this phone.")
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)
        .multilineTextAlignment(.center)
        .padding(.horizontal, theme.spacing.xl)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.palette.groupedBackground.color)
  }

  private func mapCanvas(_ timeline: LocationTimeline) -> some View {
    GeometryReader { geo in
      ZStack {
        // Fictional local map — original geometry, not a real basemap tile.
        FictionalCityMap()
          .clipShape(Rectangle())

        ForEach(timeline.visits) { visit in
          let selected = visit.id == selectedVisitId
          Button {
            selectedVisitId = visit.id
          } label: {
            VStack(spacing: 2) {
              Image(systemName: selected ? "mappin.circle.fill" : "mappin.circle")
                .font(theme.fonts.font(selected ? 28 : 22))
                .foregroundStyle(
                  selected
                    ? theme.palette.destructive.color
                    : theme.palette.iconPlaces.color
                )
                .shadow(color: theme.palette.primaryText.color.opacity(0.25), radius: 2, y: 1)
              if selected {
                Text(shortLabel(visit.label))
                  .font(theme.fonts.captionFont)
                  .fontWeight(.semibold)
                  .foregroundStyle(theme.palette.primaryText.color)
                  .padding(.horizontal, theme.spacing.xs)
                  .padding(.vertical, 2)
                  .background(
                    theme.palette.elevatedBackground.color.opacity(0.94),
                    in: Capsule()
                  )
              }
            }
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("maps-pin-\(visit.placeId ?? visit.label)")
          .position(
            x: geo.size.width * visit.x,
            y: geo.size.height * visit.y
          )
        }

        VStack {
          HStack {
            Text(timeline.regionName)
              .font(theme.fonts.subheadlineFont)
              .fontWeight(.semibold)
              .foregroundStyle(theme.palette.primaryText.color)
              .padding(.horizontal, theme.spacing.sm)
              .padding(.vertical, theme.spacing.xs)
              .background(
                theme.palette.elevatedBackground.color.opacity(0.92),
                in: Capsule()
              )
            Spacer()
          }
          .padding(theme.spacing.md)
          Spacer()
        }
      }
    }
    .background(theme.palette.groupedBackground.color)
  }

  private func visitList(_ timeline: LocationTimeline) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Timeline")
        .font(theme.fonts.headlineFont)
        .foregroundStyle(theme.palette.primaryText.color)
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.sm)
        .padding(.bottom, theme.spacing.xs)

      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(timeline.visits) { visit in
            Button {
              selectedVisitId = visit.id
            } label: {
              HStack(alignment: .top, spacing: theme.spacing.md) {
                Circle()
                  .fill(
                    visit.id == selectedVisitId
                      ? theme.palette.destructive.color
                      : theme.palette.iconPlaces.color
                  )
                  .frame(width: 10, height: 10)
                  .padding(.top, 6)

                VStack(alignment: .leading, spacing: 2) {
                  Text(visit.label)
                    .font(theme.fonts.headlineFont)
                    .foregroundStyle(theme.palette.primaryText.color)
                  Text(visitMeta(visit))
                    .font(theme.fonts.footnoteFont)
                    .foregroundStyle(theme.palette.secondaryText.color)
                }
                Spacer()
              }
              .padding(.horizontal, theme.spacing.md)
              .padding(.vertical, theme.spacing.sm)
              .background(
                visit.id == selectedVisitId
                  ? theme.palette.accent.color.opacity(0.08)
                  : theme.palette.elevatedBackground.color
              )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("maps-visit-\(visit.placeId ?? visit.label)")

            Rectangle()
              .fill(theme.palette.separator.color)
              .frame(height: 0.33)
              .padding(.leading, theme.spacing.md + 22)
          }
        }
      }
    }
    .background(theme.palette.elevatedBackground.color)
  }

  private func visitMeta(_ visit: LocationVisit) -> String {
    let when = formatWhen(visit.at)
    if let mins = visit.durationMin {
      let hours = mins / 60
      let rem = mins % 60
      if hours > 0 {
        return "\(when) · \(hours)h \(rem)m"
      }
      return "\(when) · \(mins) min"
    }
    return when
  }

  private func formatWhen(_ iso: String) -> String {
    let parser = ISO8601DateFormatter()
    parser.formatOptions = [.withInternetDateTime]
    guard let date = parser.date(from: iso) else { return iso }
    let f = DateFormatter()
    f.dateFormat = "EEE d MMM · h:mm a"
    return f.string(from: date)
  }

  private func shortLabel(_ label: String) -> String {
    if let head = label.split(separator: "—").first {
      return String(head).trimmingCharacters(in: .whitespaces)
    }
    return label
  }
}

/// Hand-drawn fictional district — not a real city basemap.
struct FictionalCityMap: View {
  @Environment(\.carveTheme) private var theme

  var body: some View {
    Canvas { context, size in
      let bg = theme.palette.groupedBackground.color
      context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bg))

      // Water
      var river = Path()
      river.move(to: CGPoint(x: 0, y: size.height * 0.62))
      river.addCurve(
        to: CGPoint(x: size.width, y: size.height * 0.48),
        control1: CGPoint(x: size.width * 0.3, y: size.height * 0.7),
        control2: CGPoint(x: size.width * 0.7, y: size.height * 0.4))
      river.addLine(to: CGPoint(x: size.width, y: size.height * 0.58))
      river.addCurve(
        to: CGPoint(x: 0, y: size.height * 0.72),
        control1: CGPoint(x: size.width * 0.65, y: size.height * 0.5),
        control2: CGPoint(x: size.width * 0.25, y: size.height * 0.8))
      river.closeSubpath()
      context.fill(river, with: .color(theme.palette.accent.color.opacity(0.22)))

      // Blocks
      let park = theme.palette.iconPlaces.color.opacity(0.18)
      let blockRadius = theme.radii.chip
      context.fill(
        Path(roundedRect: CGRect(
          x: size.width * 0.12, y: size.height * 0.12,
          width: size.width * 0.28, height: size.height * 0.18),
          cornerRadius: blockRadius),
        with: .color(park))
      context.fill(
        Path(roundedRect: CGRect(
          x: size.width * 0.55, y: size.height * 0.18,
          width: size.width * 0.32, height: size.height * 0.22),
          cornerRadius: blockRadius),
        with: .color(theme.palette.secondaryText.color.opacity(0.08)))

      // Roads
      var roads = Path()
      for i in 1..<5 {
        let y = size.height * (0.15 + Double(i) * 0.15)
        roads.move(to: CGPoint(x: 0, y: y))
        roads.addLine(to: CGPoint(x: size.width, y: y))
      }
      for i in 1..<4 {
        let x = size.width * (0.18 + Double(i) * 0.2)
        roads.move(to: CGPoint(x: x, y: 0))
        roads.addLine(to: CGPoint(x: x, y: size.height))
      }
      context.stroke(
        roads,
        with: .color(theme.palette.elevatedBackground.color),
        lineWidth: 10)
      context.stroke(
        roads,
        with: .color(theme.palette.separator.color.opacity(0.7)),
        lineWidth: 1.2)
    }
  }
}
