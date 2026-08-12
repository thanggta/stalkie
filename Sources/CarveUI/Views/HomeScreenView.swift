// Sources/CarveUI/Views/HomeScreenView.swift
import SwiftUI
import CarveShell

struct HomeScreenView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  private let apps: [PhoneAppId] = PhoneAppId.allCases

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          theme.palette.homeWallpaperTop.color,
          theme.palette.homeWallpaperBottom.color,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        Text(session.caseFile.title)
          .font(theme.fonts.titleFont)
          .foregroundStyle(theme.palette.iconLabel.color)
          .padding(.horizontal, theme.spacing.lg)
          .padding(.top, theme.spacing.md)

        LazyVGrid(
          columns: [
            GridItem(.flexible(), spacing: theme.icon.gridSpacing),
            GridItem(.flexible(), spacing: theme.icon.gridSpacing),
            GridItem(.flexible(), spacing: theme.icon.gridSpacing),
            GridItem(.flexible(), spacing: theme.icon.gridSpacing),
          ],
          spacing: theme.icon.gridSpacing
        ) {
          ForEach(apps, id: \.self) { app in
            Button {
              path.append(.app(app))
            } label: {
              AppIconCell(
                appId: app,
                badge: session.badgeCount(for: app),
                pulse: session.badgeCount(for: app) > 0
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, theme.spacing.lg)

        Spacer()

        verdictEntry
          .padding(.horizontal, theme.spacing.lg)
          .padding(.bottom, theme.spacing.xl)
      }
    }
  }

  @ViewBuilder
  private var verdictEntry: some View {
    if session.isFiled {
      Button {
        path.append(.verdictResults)
      } label: {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("What you decided")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
          Text("Read it again")
            .font(theme.fonts.footnoteFont)
            .foregroundStyle(theme.palette.badgeText.color.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
          theme.palette.unlockBannerBackground.color,
          in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
        )
      }
      .buttonStyle(.plain)
    } else {
      Button {
        path.append(.verdict)
      } label: {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("When you put the phone down")
            .font(theme.fonts.headlineFont)
            .foregroundStyle(theme.palette.badgeText.color)
          Text(
            session.answeredCount == 0
              ? "You will have decided what you believe."
              : "\(session.answeredCount) of \(session.caseFile.questions.count) answered — not filed yet."
          )
          .font(theme.fonts.footnoteFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
          theme.palette.destructive.color,
          in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
        )
      }
      .buttonStyle(.plain)
    }
  }
}

struct AppIconCell: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId
  let badge: Int
  let pulse: Bool

  @State private var pulseOn = false

  var body: some View {
    VStack(spacing: theme.icon.labelSpacing) {
      ZStack(alignment: .topTrailing) {
        AppGlyph(appId: appId)
          .frame(width: theme.icon.size, height: theme.icon.size)
          .scaleEffect(pulse && pulseOn ? 1.06 : 1.0)
          .animation(
            pulse
              ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
              : .default,
            value: pulseOn
          )

        if badge > 0 {
          Text(badge > 9 ? "9+" : "\(badge)")
            .font(theme.fonts.captionFont)
            .foregroundStyle(theme.palette.badgeText.color)
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xxs)
            .background(
              theme.palette.badge.color,
              in: Capsule()
            )
            .offset(x: theme.spacing.xs, y: -theme.spacing.xs)
        }
      }
      Text(appId.title)
        .font(theme.fonts.iconLabelFont)
        .foregroundStyle(theme.palette.iconLabel.color)
        .lineLimit(1)
    }
    .onAppear { pulseOn = pulse }
    .onChange(of: pulse) { _, new in pulseOn = new }
  }
}

/// Originally drawn app glyphs — never Apple artwork (compliance §1.1).
struct AppGlyph: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId

  var body: some View {
    let fill = glyphFill
    ZStack {
      iconBackground(fill: fill)
      glyphMark
        .foregroundStyle(theme.palette.badgeText.color)
    }
  }

  private var glyphFill: ThemeColor {
    switch appId {
    case .messages: return theme.palette.iconMessages
    case .notes: return theme.palette.iconNotes
    case .phone: return theme.palette.iconPhone
    case .photos: return theme.palette.iconPhotos
    case .places: return theme.palette.iconPlaces
    case .board: return theme.palette.accent
    }
  }

  @ViewBuilder
  private func iconBackground(fill: ThemeColor) -> some View {
    switch theme.icon.kind {
    case .roundedSquare:
      RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
        .fill(fill.color)
    case .circle:
      Circle().fill(fill.color)
    case .hexagon:
      HexagonShape()
        .fill(fill.color)
    }
  }

  @ViewBuilder
  private var glyphMark: some View {
    switch appId {
    case .messages:
      // Simple chat bubble outline — original geometry.
      BubbleGlyph()
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .padding(theme.spacing.md)
    case .notes:
      RoundedRectangle(cornerRadius: theme.radii.chip * 0.4, style: .continuous)
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .padding(theme.spacing.md)
        .overlay(
          VStack(spacing: theme.spacing.xxs) {
            ForEach(0..<3, id: \.self) { _ in
              Capsule()
                .fill(theme.palette.badgeText.color)
                .frame(height: 2)
            }
          }
          .padding(.horizontal, theme.spacing.lg)
        )
    case .phone:
      Capsule()
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .rotationEffect(.degrees(-45))
        .padding(theme.spacing.lg)
    case .photos:
      Circle()
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .padding(theme.spacing.lg)
    case .places:
      PinGlyph()
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .padding(theme.spacing.md)
    case .board:
      LinkGlyph()
        .stroke(theme.palette.badgeText.color, lineWidth: 2)
        .padding(theme.spacing.md)
    }
  }
}

private struct BubbleGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let r = min(rect.width, rect.height) * 0.2
    p.addRoundedRect(in: CGRect(
      x: rect.minX + rect.width * 0.1,
      y: rect.minY + rect.height * 0.1,
      width: rect.width * 0.8,
      height: rect.height * 0.55
    ), cornerSize: CGSize(width: r, height: r))
    p.move(to: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.minY + rect.height * 0.65))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.2, y: rect.minY + rect.height * 0.85))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.05, y: rect.minY + rect.height * 0.65))
    return p
  }
}

private struct PinGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let c = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.1)
    p.addEllipse(in: CGRect(x: c.x - rect.width * 0.2, y: c.y - rect.height * 0.2,
                            width: rect.width * 0.4, height: rect.height * 0.4))
    p.move(to: CGPoint(x: rect.midX, y: c.y + rect.height * 0.15))
    p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.1))
    return p
  }
}

private struct LinkGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let left = CGPoint(x: rect.minX + rect.width * 0.28, y: rect.midY)
    let right = CGPoint(x: rect.maxX - rect.width * 0.28, y: rect.midY)
    let r = min(rect.width, rect.height) * 0.14
    p.addEllipse(in: CGRect(x: left.x - r, y: left.y - r, width: r * 2, height: r * 2))
    p.addEllipse(in: CGRect(x: right.x - r, y: right.y - r, width: r * 2, height: r * 2))
    p.move(to: left)
    p.addLine(to: right)
    return p
  }
}

struct HexagonShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height
    let points: [CGPoint] = [
      CGPoint(x: w * 0.25, y: 0),
      CGPoint(x: w * 0.75, y: 0),
      CGPoint(x: w, y: h * 0.5),
      CGPoint(x: w * 0.75, y: h),
      CGPoint(x: w * 0.25, y: h),
      CGPoint(x: 0, y: h * 0.5),
    ]
    p.move(to: CGPoint(x: rect.minX + points[0].x, y: rect.minY + points[0].y))
    for pt in points.dropFirst() {
      p.addLine(to: CGPoint(x: rect.minX + pt.x, y: rect.minY + pt.y))
    }
    p.closeSubpath()
    return p
  }
}
