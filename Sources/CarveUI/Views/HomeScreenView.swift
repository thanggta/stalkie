// Sources/CarveUI/Views/HomeScreenView.swift
// Unlocked home screen. Structure mirrors a real phone: wallpaper, icon page,
// page dots, frosted dock — not a titled game lobby.

import SwiftUI
import CarveShell

struct HomeScreenView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  /// Apps that live on the home page (not the dock).
  private var pageApps: [PhoneAppId] {
    PhoneAppId.allCases.filter { !Self.dockApps.contains($0) }
  }

  /// Classic four-up dock.
  private static let dockApps: [PhoneAppId] = [.phone, .messages, .photos, .notes]

  var body: some View {
    ZStack {
      wallpaper
        .ignoresSafeArea()
        .onLongPressGesture(minimumDuration: 0.7) {
          // Theme retreat lives here, not in the status bar.
          cycleTheme()
        }

      VStack(spacing: 0) {
        // Leave room for the overlaid status chrome.
        Spacer()
          .frame(height: theme.statusBar.height)

        iconPage
          .padding(.top, theme.spacing.lg)

        Spacer(minLength: theme.spacing.md)

        pageDots
          .padding(.bottom, theme.spacing.sm)

        decidePill
          .padding(.horizontal, theme.spacing.lg)
          .padding(.bottom, theme.spacing.sm)

        dock
          .padding(.horizontal, theme.spacing.md)
          .padding(.bottom, theme.spacing.md)
      }
    }
  }

  // MARK: - Wallpaper

  private var wallpaper: some View {
    ZStack {
      // Layered gradients — reads photographic, not a flat fill.
      LinearGradient(
        colors: [
          theme.palette.homeWallpaperTop.color,
          theme.palette.accent.color.opacity(0.55),
          theme.palette.homeWallpaperBottom.color,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      RadialGradient(
        colors: [
          theme.palette.badgeText.color.opacity(0.18),
          theme.palette.badgeText.color.opacity(0),
        ],
        center: .topTrailing,
        startRadius: 20,
        endRadius: 320
      )
      RadialGradient(
        colors: [
          theme.palette.iconPhotos.color.opacity(0.35),
          theme.palette.iconPhotos.color.opacity(0),
        ],
        center: UnitPoint(x: 0.15, y: 0.75),
        startRadius: 10,
        endRadius: 280
      )
    }
  }

  // MARK: - Icon page

  private var iconPage: some View {
    LazyVGrid(
      columns: [
        GridItem(.flexible(), spacing: theme.icon.gridSpacing),
        GridItem(.flexible(), spacing: theme.icon.gridSpacing),
        GridItem(.flexible(), spacing: theme.icon.gridSpacing),
        GridItem(.flexible(), spacing: theme.icon.gridSpacing),
      ],
      spacing: theme.icon.gridSpacing + 8
    ) {
      ForEach(pageApps, id: \.self) { app in
        iconButton(app)
      }
    }
    .padding(.horizontal, theme.spacing.lg)
  }

  private func iconButton(_ app: PhoneAppId) -> some View {
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

  private var pageDots: some View {
    HStack(spacing: theme.spacing.xs) {
      Circle()
        .fill(theme.palette.badgeText.color.opacity(0.95))
        .frame(width: 7, height: 7)
      Circle()
        .fill(theme.palette.badgeText.color.opacity(0.28))
        .frame(width: 7, height: 7)
    }
  }

  // MARK: - Decide (ending, not a resource bar)

  private var decidePill: some View {
    Button {
      path.append(session.isFiled ? .verdictResults : .verdict)
    } label: {
      HStack(spacing: theme.spacing.sm) {
        VStack(alignment: .leading, spacing: 2) {
          Text(session.isFiled ? "What you decided" : "When you put the phone down")
            .font(theme.fonts.subheadlineFont)
            .fontWeight(.semibold)
            .foregroundStyle(theme.palette.badgeText.color)
          Text(
            session.isFiled
              ? "Read it again"
              : (session.answeredCount == 0
                ? "You will have decided what you believe."
                : "\(session.answeredCount) of \(session.caseFile.questions.count) answered")
          )
          .font(theme.fonts.captionFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.78))
        }
        Spacer(minLength: 0)
        Text("›")
          .font(theme.fonts.headlineFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.7))
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm)
      .background(
        theme.palette.unlockBannerBackground.color.opacity(0.55),
        in: RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
          .stroke(theme.palette.badgeText.color.opacity(0.12), lineWidth: 0.5)
      )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Dock

  private var dock: some View {
    HStack {
      ForEach(Self.dockApps, id: \.self) { app in
        Spacer(minLength: 0)
        iconButton(app)
        Spacer(minLength: 0)
      }
    }
    .padding(.horizontal, theme.spacing.sm)
    .padding(.vertical, theme.spacing.sm)
    .background(
      RoundedRectangle(cornerRadius: theme.radii.banner + 8, style: .continuous)
        .fill(theme.palette.elevatedBackground.color.opacity(0.28))
        .background(
          RoundedRectangle(cornerRadius: theme.radii.banner + 8, style: .continuous)
            .fill(theme.palette.badgeText.color.opacity(0.12))
        )
        .overlay(
          RoundedRectangle(cornerRadius: theme.radii.banner + 8, style: .continuous)
            .stroke(theme.palette.badgeText.color.opacity(0.22), lineWidth: 0.5)
        )
    )
  }

  private func cycleTheme() {
    let all = Theme.allBuiltIn
    guard let idx = all.firstIndex(where: { $0.id == session.themeId }) else { return }
    let next = all[(idx + 1) % all.count]
    session.setTheme(next.id)
  }
}

// MARK: - Icon cell

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
          .shadow(
            color: theme.palette.primaryText.color.opacity(0.28),
            radius: 8,
            y: 4
          )
          .scaleEffect(pulse && pulseOn ? 1.04 : 1.0)
          .animation(
            pulse
              ? .easeInOut(duration: 0.85).repeatForever(autoreverses: true)
              : .default,
            value: pulseOn
          )

        if badge > 0 {
          Text(badge > 9 ? "9+" : "\(badge)")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.badgeText.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(theme.palette.badge.color, in: Capsule())
            .offset(x: 4, y: -4)
        }
      }
      Text(appId.title)
        .font(theme.fonts.iconLabelFont)
        .foregroundStyle(theme.palette.iconLabel.color)
        .lineLimit(1)
        .shadow(color: theme.palette.primaryText.color.opacity(0.35), radius: 1, y: 0.5)
    }
    .frame(maxWidth: .infinity)
    .onAppear { pulseOn = pulse }
    .onChange(of: pulse) { _, new in pulseOn = new }
  }
}

// MARK: - Glyphs (original geometry — never Apple artwork)

struct AppGlyph: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId

  var body: some View {
    ZStack {
      iconBackground
      glyphMark
    }
  }

  private var base: ThemeColor {
    switch appId {
    case .messages: return theme.palette.iconMessages
    case .notes: return theme.palette.iconNotes
    case .phone: return theme.palette.iconPhone
    case .photos: return theme.palette.iconPhotos
    case .places: return theme.palette.iconPlaces
    case .board: return theme.palette.accent
    }
  }

  /// Top-lit fill — the single biggest "this is a phone icon" cue.
  @ViewBuilder
  private var iconBackground: some View {
    let top = base.color
    let bottom = base.color.opacity(0.78)
    let gradient = LinearGradient(
      colors: [top, bottom],
      startPoint: .top,
      endPoint: .bottom
    )
    switch theme.icon.kind {
    case .roundedSquare:
      RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
        .fill(gradient)
        .overlay(
          RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
            .stroke(theme.palette.badgeText.color.opacity(0.12), lineWidth: 0.5)
        )
    case .circle:
      Circle().fill(gradient)
    case .hexagon:
      HexagonShape().fill(gradient)
    }
  }

  @ViewBuilder
  private var glyphMark: some View {
    let mark = theme.palette.badgeText.color
    switch appId {
    case .messages:
      BubbleGlyph()
        .fill(mark)
        .padding(theme.spacing.md + 2)
    case .notes:
      ZStack {
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.4, style: .continuous)
          .fill(mark.opacity(0.95))
          .padding(theme.spacing.md)
        VStack(spacing: 3) {
          ForEach(0..<3, id: \.self) { _ in
            Capsule()
              .fill(base.color.opacity(0.55))
              .frame(height: 2)
          }
        }
        .padding(.horizontal, theme.spacing.lg + 2)
      }
    case .phone:
      PhoneHandsetGlyph()
        .fill(mark)
        .padding(theme.spacing.lg)
        .rotationEffect(.degrees(-40))
    case .photos:
      // Flower-like original mark — not Apple's Photos asset.
      PhotoFlowerGlyph()
        .fill(mark)
        .padding(theme.spacing.md + 1)
    case .places:
      PinGlyph()
        .fill(mark)
        .padding(theme.spacing.md + 2)
    case .board:
      LinkGlyph()
        .stroke(mark, lineWidth: 2.2)
        .padding(theme.spacing.md)
    }
  }
}

private struct BubbleGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let r = min(rect.width, rect.height) * 0.22
    let body = CGRect(
      x: rect.minX + rect.width * 0.08,
      y: rect.minY + rect.height * 0.08,
      width: rect.width * 0.84,
      height: rect.height * 0.58
    )
    p.addRoundedRect(in: body, cornerSize: CGSize(width: r, height: r))
    p.move(to: CGPoint(x: rect.midX - rect.width * 0.08, y: body.maxY))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY - rect.height * 0.08))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.06, y: body.maxY))
    p.closeSubpath()
    return p
  }
}

/// Classic handset silhouette — original geometry, not Apple's phone glyph.
private struct PhoneHandsetGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height
    // Upper ear cup
    p.addRoundedRect(
      in: CGRect(x: rect.minX + w * 0.18, y: rect.minY + h * 0.12,
                 width: w * 0.34, height: h * 0.28),
      cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
    // Lower mouth cup
    p.addRoundedRect(
      in: CGRect(x: rect.minX + w * 0.48, y: rect.minY + h * 0.58,
                 width: w * 0.34, height: h * 0.28),
      cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
    // Connecting bar
    var bar = Path()
    bar.move(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.28))
    bar.addQuadCurve(
      to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.68),
      control: CGPoint(x: rect.minX + w * 0.72, y: rect.minY + h * 0.48))
    bar.addLine(to: CGPoint(x: rect.minX + w * 0.48, y: rect.minY + h * 0.72))
    bar.addQuadCurve(
      to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.32),
      control: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.52))
    bar.closeSubpath()
    p.addPath(bar)
    return p
  }
}

private struct PinGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let head = CGRect(
      x: rect.midX - rect.width * 0.22,
      y: rect.minY + rect.height * 0.08,
      width: rect.width * 0.44,
      height: rect.height * 0.44
    )
    p.addEllipse(in: head)
    p.move(to: CGPoint(x: rect.midX, y: head.midY + head.height * 0.2))
    p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.08))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.maxY - rect.height * 0.2))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.maxY - rect.height * 0.2))
    p.closeSubpath()
    return p
  }
}

private struct PhotoFlowerGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let petalR = min(rect.width, rect.height) * 0.22
    for i in 0..<6 {
      let angle = Double(i) * (.pi / 3) - .pi / 2
      let cx = c.x + cos(angle) * petalR * 0.85
      let cy = c.y + sin(angle) * petalR * 0.85
      p.addEllipse(in: CGRect(x: cx - petalR * 0.55, y: cy - petalR * 0.55,
                              width: petalR * 1.1, height: petalR * 1.1))
    }
    p.addEllipse(in: CGRect(x: c.x - petalR * 0.35, y: c.y - petalR * 0.35,
                            width: petalR * 0.7, height: petalR * 0.7))
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
