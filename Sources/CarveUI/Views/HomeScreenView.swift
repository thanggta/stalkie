// Sources/CarveUI/Views/HomeScreenView.swift
// Unlocked home screen. Dense icon page + dock — not a sparse game lobby.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import CarveShell

struct HomeScreenView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  @Binding var path: [PhoneRoute]

  /// Four-up dock (classic phone layout).
  private static let dockApps: [PhoneAppId] = [.phone, .messages, .photos, .browser]

  /// Everything else on the page, including Decide (no narrative banner over the dock).
  private var pageApps: [PhoneAppId] {
    PhoneAppId.allCases.filter { !Self.dockApps.contains($0) }
  }

  var body: some View {
    ZStack {
      wallpaper
        .ignoresSafeArea()
        .onLongPressGesture(minimumDuration: 0.7) {
          cycleTheme()
        }

      VStack(spacing: 0) {
        Spacer().frame(height: theme.statusBar.height)

        iconPage
          .padding(.top, theme.spacing.md)

        Spacer(minLength: theme.spacing.sm)

        // Single page for now — one lit dot only (two dots looked fake with one page).
        Circle()
          .fill(theme.palette.badgeText.color.opacity(0.9))
          .frame(width: 7, height: 7)
          .padding(.bottom, theme.spacing.sm)

        dock
          .padding(.horizontal, theme.spacing.md)
          .padding(.bottom, theme.spacing.lg)
      }
    }
  }

  // MARK: - Wallpaper

  private var wallpaper: some View {
    ZStack {
      if let name = theme.homeWallpaperAsset, let img = HomeWallpaper.image(named: name) {
        img
          .resizable()
          .scaledToFill()
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
          .clipped()
      } else {
        // Saturated gradient fallback if the asset is missing from the bundle.
        LinearGradient(
          colors: [
            theme.palette.homeWallpaperTop.color,
            theme.palette.accent.color,
            theme.palette.homeWallpaperBottom.color,
            theme.palette.iconPhotos.color,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
      // Gentle top shade only — status glyphs stay readable without washing the image out.
      LinearGradient(
        colors: [
          theme.palette.primaryText.color.opacity(0.18),
          theme.palette.primaryText.color.opacity(0),
        ],
        startPoint: .top,
        endPoint: UnitPoint(x: 0.5, y: 0.22)
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
      spacing: theme.icon.gridSpacing + 10
    ) {
      ForEach(pageApps, id: \.self) { app in
        iconButton(app)
      }
    }
    .padding(.horizontal, theme.spacing.lg)
  }

  private func iconButton(_ app: PhoneAppId) -> some View {
    Button {
      switch app {
      case .decide:
        path.append(session.isFiled ? .verdictResults : .verdict)
      default:
        path.append(.app(app))
      }
    } label: {
      AppIconCell(
        appId: app,
        badge: badge(for: app),
        pulse: badge(for: app) > 0
      )
    }
    .buttonStyle(.plain)
  }

  private func badge(for app: PhoneAppId) -> Int {
    if app == .decide {
      return session.isFiled ? 0 : (session.allQuestionsAnswered ? 1 : 0)
    }
    return session.badgeCount(for: app)
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
    .padding(.vertical, theme.spacing.sm + 2)
    .background(
      RoundedRectangle(cornerRadius: theme.radii.banner + 10, style: .continuous)
        .fill(theme.palette.elevatedBackground.color.opacity(0.32))
        .background(
          RoundedRectangle(cornerRadius: theme.radii.banner + 10, style: .continuous)
            .fill(theme.palette.badgeText.color.opacity(0.14))
        )
        .overlay(
          RoundedRectangle(cornerRadius: theme.radii.banner + 10, style: .continuous)
            .stroke(theme.palette.badgeText.color.opacity(0.28), lineWidth: 0.5)
        )
    )
  }

  private func cycleTheme() {
    let all = Theme.allBuiltIn
    guard let idx = all.firstIndex(where: { $0.id == session.themeId }) else { return }
    session.setTheme(all[(idx + 1) % all.count].id)
  }
}

/// Resolve wallpaper from SPM module bundle or the app main bundle (Xcode packaging).
enum HomeWallpaper {
  static func image(named name: String) -> Image? {
    var candidates: [Bundle] = [.module, .main]
    if let url = Bundle.main.url(forResource: "CarveCore_CarveUI", withExtension: "bundle"),
      let b = Bundle(url: url)
    {
      candidates.insert(b, at: 0)
    }
    for bundle in candidates {
      // Loose PNG resources are not always found by Image(_:bundle:); load via platform image.
      #if canImport(UIKit)
      if let ui = UIImage(named: name, in: bundle, with: nil) {
        return Image(uiImage: ui)
      }
      if let url = bundle.url(forResource: name, withExtension: "png"),
        let data = try? Data(contentsOf: url),
        let ui = UIImage(data: data)
      {
        return Image(uiImage: ui)
      }
      #elseif canImport(AppKit)
      if let url = bundle.url(forResource: name, withExtension: "png"),
        let ns = NSImage(contentsOf: url)
      {
        return Image(nsImage: ns)
      }
      #endif
    }
    return nil
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
            color: theme.palette.primaryText.color.opacity(0.3),
            radius: 10,
            y: 5
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
        .minimumScaleFactor(0.8)
        .shadow(color: theme.palette.primaryText.color.opacity(0.4), radius: 1.5, y: 0.5)
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
    case .decide: return theme.palette.destructive
    case .calendar: return theme.palette.destructive
    case .camera: return theme.palette.tertiaryText
    case .browser: return theme.palette.accent
    case .mail: return theme.palette.accent
    case .settings: return theme.palette.secondaryText
    case .music: return theme.palette.iconPhotos
    }
  }

  @ViewBuilder
  private var iconBackground: some View {
    let gradient = LinearGradient(
      colors: [base.color, base.color.opacity(0.78)],
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
      // Solid filled bubble — closer to the real Messages mark language.
      BubbleGlyph()
        .fill(mark)
        .padding(theme.spacing.md + 1)
    case .notes:
      ZStack {
        RoundedRectangle(cornerRadius: theme.radii.chip * 0.4, style: .continuous)
          .fill(mark.opacity(0.95))
          .padding(theme.spacing.md)
        VStack(spacing: 3) {
          ForEach(0..<3, id: \.self) { _ in
            Capsule().fill(base.color.opacity(0.55)).frame(height: 2)
          }
        }
        .padding(.horizontal, theme.spacing.lg + 2)
      }
    case .phone:
      PhoneHandsetGlyph().fill(mark).padding(theme.spacing.md + 2)
    case .photos:
      PhotoFlowerGlyph().fill(mark).padding(theme.spacing.md + 1)
    case .places:
      PinGlyph().fill(mark).padding(theme.spacing.md + 2)
    case .board:
      LinkGlyph().stroke(mark, lineWidth: 2.2).padding(theme.spacing.md)
    case .decide:
      // Scale / balance — filing a verdict, not a game controller.
      DecideGlyph().stroke(mark, lineWidth: 2).padding(theme.spacing.md + 2)
    case .calendar:
      CalendarGlyph(mark: mark, ink: base.color)
    case .camera:
      CameraGlyph().stroke(mark, lineWidth: 2).padding(theme.spacing.md)
    case .browser:
      ZStack {
        Circle()
          .stroke(mark, lineWidth: 2.2)
          .padding(theme.spacing.md)
        CompassGlyph()
          .fill(mark)
          .padding(theme.spacing.lg - 1)
      }
    case .mail:
      EnvelopeGlyph().stroke(mark, lineWidth: 2).padding(theme.spacing.md)
    case .settings:
      GearGlyph().stroke(mark, lineWidth: 1.8).padding(theme.spacing.md + 1)
    case .music:
      MusicGlyph().fill(mark).padding(theme.spacing.md + 2)
    }
  }
}

// MARK: Shape library

private struct BubbleGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let r = min(rect.width, rect.height) * 0.22
    let body = CGRect(
      x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.08,
      width: rect.width * 0.84, height: rect.height * 0.58)
    p.addRoundedRect(in: body, cornerSize: CGSize(width: r, height: r))
    p.move(to: CGPoint(x: rect.midX - rect.width * 0.08, y: body.maxY))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.maxY - rect.height * 0.08))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.06, y: body.maxY))
    p.closeSubpath()
    return p
  }
}

/// Classic telephone handset (C-curve) — must not read as share/link.
private struct PhoneHandsetGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height
    // Outer C
    p.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.18))
    p.addCurve(
      to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.82),
      control1: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.28),
      control2: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.72))
    p.addCurve(
      to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.70),
      control1: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.86),
      control2: CGPoint(x: rect.minX + w * 0.46, y: rect.minY + h * 0.78))
    p.addCurve(
      to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.30),
      control1: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.62),
      control2: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.38))
    p.addCurve(
      to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.18),
      control1: CGPoint(x: rect.minX + w * 0.46, y: rect.minY + h * 0.22),
      control2: CGPoint(x: rect.minX + w * 0.38, y: rect.minY + h * 0.14))
    p.closeSubpath()
    // Ear pad
    p.addEllipse(in: CGRect(
      x: rect.minX + w * 0.30, y: rect.minY + h * 0.12,
      width: w * 0.38, height: h * 0.28))
    // Mouth pad
    p.addEllipse(in: CGRect(
      x: rect.minX + w * 0.30, y: rect.minY + h * 0.60,
      width: w * 0.38, height: h * 0.28))
    return p
  }
}

private struct PinGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let head = CGRect(
      x: rect.midX - rect.width * 0.22, y: rect.minY + rect.height * 0.08,
      width: rect.width * 0.44, height: rect.height * 0.44)
    p.addEllipse(in: head)
    p.move(to: CGPoint(x: rect.midX, y: head.midY + head.height * 0.25))
    p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.06))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.maxY - rect.height * 0.22))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY - rect.height * 0.22))
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
      p.addEllipse(in: CGRect(
        x: cx - petalR * 0.55, y: cy - petalR * 0.55,
        width: petalR * 1.1, height: petalR * 1.1))
    }
    p.addEllipse(in: CGRect(
      x: c.x - petalR * 0.35, y: c.y - petalR * 0.35,
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

private struct DecideGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    // Simple balance beam
    p.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY))
    p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.midY))
    p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.2))
    p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.15))
    p.addEllipse(in: CGRect(
      x: rect.minX + rect.width * 0.12, y: rect.midY - rect.height * 0.12,
      width: rect.width * 0.18, height: rect.height * 0.18))
    p.addEllipse(in: CGRect(
      x: rect.maxX - rect.width * 0.3, y: rect.midY - rect.height * 0.12,
      width: rect.width * 0.18, height: rect.height * 0.18))
    return p
  }
}

private struct CalendarGlyph: View {
  @Environment(\.carveTheme) private var theme
  let mark: Color
  let ink: Color

  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(mark.opacity(0.95))
        .frame(height: 10)
      Text("12")
        .font(theme.fonts.headlineFont)
        .fontWeight(.bold)
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(mark.opacity(0.95))
    }
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.chip * 0.35, style: .continuous))
    .padding(theme.spacing.md)
  }
}

private struct CameraGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let body = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.22)
    p.addRoundedRect(
      in: body,
      cornerSize: CGSize(width: body.width * 0.12, height: body.width * 0.12))
    p.addEllipse(in: CGRect(
      x: rect.midX - rect.width * 0.16, y: rect.midY - rect.height * 0.16,
      width: rect.width * 0.32, height: rect.height * 0.32))
    return p
  }
}

/// Safari-like compass mark — ring + diamond needle (original geometry).
private struct CompassGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let inset = rect.insetBy(dx: rect.width * 0.14, dy: rect.height * 0.14)
    p.addEllipse(in: inset)
    // Needle diamond
    p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.22))
    p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.14, y: rect.midY))
    p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.22))
    p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.14, y: rect.midY))
    p.closeSubpath()
    // Inner hub
    let hub = min(rect.width, rect.height) * 0.08
    p.addEllipse(in: CGRect(x: rect.midX - hub, y: rect.midY - hub, width: hub * 2, height: hub * 2))
    return p
  }
}

private struct EnvelopeGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let r = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.22)
    p.addRoundedRect(in: r, cornerSize: CGSize(width: r.width * 0.08, height: r.width * 0.08))
    p.move(to: CGPoint(x: r.minX, y: r.minY + 2))
    p.addLine(to: CGPoint(x: r.midX, y: r.midY + 2))
    p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 2))
    return p
  }
}

private struct GearGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) * 0.38
    let inner = outer * 0.55
    for i in 0..<8 {
      let a0 = Double(i) * (.pi / 4) - .pi / 8
      let a1 = a0 + .pi / 8
      p.addArc(center: c, radius: outer, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
      p.addArc(center: c, radius: inner, startAngle: .radians(a1), endAngle: .radians(a0 + .pi / 4), clockwise: false)
    }
    p.closeSubpath()
    p.addEllipse(in: CGRect(x: c.x - outer * 0.28, y: c.y - outer * 0.28,
                            width: outer * 0.56, height: outer * 0.56))
    return p
  }
}

private struct MusicGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.addEllipse(in: CGRect(
      x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.42,
      width: rect.width * 0.28, height: rect.height * 0.28))
    p.addEllipse(in: CGRect(
      x: rect.minX + rect.width * 0.52, y: rect.maxY - rect.height * 0.36,
      width: rect.width * 0.28, height: rect.height * 0.28))
    p.move(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.maxY - rect.height * 0.28))
    p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.18))
    p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.12))
    p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY - rect.height * 0.22))
    return p
  }
}

struct HexagonShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let w = rect.width
    let h = rect.height
    let points: [CGPoint] = [
      CGPoint(x: w * 0.25, y: 0), CGPoint(x: w * 0.75, y: 0),
      CGPoint(x: w, y: h * 0.5), CGPoint(x: w * 0.75, y: h),
      CGPoint(x: w * 0.25, y: h), CGPoint(x: 0, y: h * 0.5),
    ]
    p.move(to: CGPoint(x: rect.minX + points[0].x, y: rect.minY + points[0].y))
    for pt in points.dropFirst() {
      p.addLine(to: CGPoint(x: rect.minX + pt.x, y: rect.minY + pt.y))
    }
    p.closeSubpath()
    return p
  }
}
