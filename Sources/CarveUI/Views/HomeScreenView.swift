// Sources/CarveUI/Views/HomeScreenView.swift
// SpringBoard-fidelity home. Layout math lives in SpringBoardLayout (tested).

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

  private static let dockApps: [PhoneAppId] = [.phone, .messages, .photos, .browser]

  /// Fill a dense first page (6 rows × 4) so mid-screen is not a lobby void.
  private static let pageOrder: [PhoneAppId] = [
    .facetime, .calendar, .photos, .camera,
    .mail, .clock, .weather, .notes,
    .reminders, .places, .health, .wallet,
    .settings, .appstore, .files, .books,
    .music, .podcasts, .tv, .homekit,
    .contacts, .calculator, .stocks, .board,
    .decide,
  ]

  private var pageApps: [PhoneAppId] {
    var seen = Set(Self.dockApps)
    var out: [PhoneAppId] = []
    for app in Self.pageOrder where !seen.contains(app) {
      out.append(app)
      seen.insert(app)
    }
    for app in PhoneAppId.allCases where !seen.contains(app) {
      out.append(app)
    }
    // Cap at 24 (6×4) so the first page stays one screen with the widget.
    return Array(out.prefix(24))
  }

  var body: some View {
    GeometryReader { geo in
      let layout = SpringBoardLayout(
        screenWidth: geo.size.width,
        screenHeight: geo.size.height,
        iconSize: theme.icon.size
      )

      ZStack {
        wallpaper
          .ignoresSafeArea()
          .onLongPressGesture(minimumDuration: 0.7) {
            cycleTheme()
          }

        VStack(spacing: 0) {
          Color.clear
            .frame(height: theme.statusBar.height + theme.spacing.xs)

          HomeMediumWidget(layout: layout)
            .padding(.horizontal, layout.sideMargin)
            .padding(.bottom, theme.spacing.md)

          iconPage(layout: layout)

          Spacer(minLength: theme.spacing.sm)

          bottomChrome(layout: layout)
        }
      }
    }
    .ignoresSafeArea()
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
        LinearGradient(
          colors: [
            theme.palette.homeWallpaperTop.color,
            theme.palette.homeWallpaperBottom.color,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      }
      LinearGradient(
        colors: [
          theme.palette.primaryText.color.opacity(0.1),
          theme.palette.primaryText.color.opacity(0),
          theme.palette.primaryText.color.opacity(0.06),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  // MARK: - Icon page

  private func iconPage(layout: SpringBoardLayout) -> some View {
    let columns = Array(
      repeating: GridItem(.fixed(layout.iconSize), spacing: layout.columnGap, alignment: .top),
      count: 4
    )

    return LazyVGrid(columns: columns, alignment: .center, spacing: layout.rowGap) {
      ForEach(pageApps, id: \.self) { app in
        iconButton(app, showLabel: true)
          .frame(width: layout.iconSize, alignment: .top)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, layout.sideMargin)
  }

  private func bottomChrome(layout: SpringBoardLayout) -> some View {
    VStack(spacing: 0) {
      pageDots(layout: layout)
        .padding(.bottom, 10)

      dock(layout: layout)

      Capsule()
        .fill(theme.palette.badgeText.color.opacity(0.35))
        .frame(width: layout.homeIndicatorWidth, height: layout.homeIndicatorHeight)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
  }

  private func pageDots(layout: SpringBoardLayout) -> some View {
    HStack(spacing: layout.pageDotSpacing) {
      Circle()
        .fill(theme.palette.badgeText.color)
        .frame(width: layout.pageDotSize, height: layout.pageDotSize)
      Circle()
        .fill(theme.palette.badgeText.color.opacity(0.32))
        .frame(width: layout.pageDotSize, height: layout.pageDotSize)
    }
  }

  private func iconButton(_ app: PhoneAppId, showLabel: Bool) -> some View {
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
        showLabel: showLabel
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(IconPressStyle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(app.title)
    .accessibilityAddTraits(.isButton)
  }

  private func badge(for app: PhoneAppId) -> Int {
    if app == .decide {
      return session.isFiled ? 0 : (session.allQuestionsAnswered ? 1 : 0)
    }
    return session.badgeCount(for: app)
  }

  private func dock(layout: SpringBoardLayout) -> some View {
    HStack(spacing: layout.columnGap) {
      ForEach(Self.dockApps, id: \.self) { app in
        iconButton(app, showLabel: false)
          .frame(width: layout.iconSize)
      }
    }
    .padding(.horizontal, layout.dockGlassBleed)
    .padding(.vertical, 12)
    .background {
      RoundedRectangle(cornerRadius: theme.radii.banner, style: .continuous)
        .fill(.ultraThinMaterial)
    }
    .shadow(color: theme.palette.primaryText.color.opacity(0.12), radius: 20, y: 10)
    .padding(.horizontal, layout.dockOuterInset)
  }

  private func cycleTheme() {
    let all = Theme.allBuiltIn
    guard let idx = all.firstIndex(where: { $0.id == session.themeId }) else { return }
    session.setTheme(all[(idx + 1) % all.count].id)
  }
}

// MARK: - Medium widget

struct HomeMediumWidget: View {
  @Environment(\.carveTheme) private var theme
  let layout: SpringBoardLayout

  var body: some View {
    HStack(alignment: .center, spacing: theme.spacing.md) {
      VStack(alignment: .leading, spacing: 1) {
        Text("Downtown")
          .font(theme.fonts.subheadlineFont)
          .fontWeight(.semibold)
          .foregroundStyle(theme.palette.badgeText.color)
        Text("72°")
          .font(theme.fonts.font(52))
          .fontWeight(.thin)
          .foregroundStyle(theme.palette.badgeText.color)
          .monospacedDigit()
          .padding(.top, -2)
        Text("Partly Cloudy")
          .font(theme.fonts.footnoteFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.92))
      }
      Spacer(minLength: 0)
      VStack(alignment: .trailing, spacing: theme.spacing.sm) {
        Image(systemName: "cloud.sun.fill")
          .font(theme.fonts.font(34))
          .symbolRenderingMode(.palette)
          .foregroundStyle(
            theme.palette.iconNotes.color,
            theme.palette.badgeText.color.opacity(0.92)
          )
          .accessibilityHidden(true)
        Text("H:76°  L:61°")
          .font(theme.fonts.captionFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.88))
          .monospacedDigit()
      }
    }
    .padding(.leading, theme.spacing.lg)
    .padding(.trailing, theme.spacing.lg - 2)
    .padding(.vertical, theme.spacing.md)
    .frame(maxWidth: .infinity)
    .frame(height: layout.widgetHeight)
    .background {
      RoundedRectangle(cornerRadius: layout.widgetCornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              theme.palette.accent.color.opacity(0.92),
              theme.palette.iconPlaces.color.opacity(0.78),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    }
    .shadow(color: theme.palette.primaryText.color.opacity(0.1), radius: 1, y: 1)
    .shadow(color: theme.palette.primaryText.color.opacity(0.16), radius: 14, y: 6)
  }
}

// MARK: - Press

private struct IconPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
      .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
  }
}

// MARK: - Loaders

enum HomeWallpaper {
  static func image(named name: String) -> Image? {
    loadImage(named: name, subdir: "Wallpapers")
  }
}

enum AppIconAsset {
  static func image(for appId: PhoneAppId) -> Image? {
    loadImage(named: appId.rawValue, subdir: "AppIcons")
  }
}

private func loadImage(named name: String, subdir: String) -> Image? {
  var candidates: [Bundle] = [.module, .main]
  if let url = Bundle.main.url(forResource: "CarveCore_CarveUI", withExtension: "bundle"),
    let b = Bundle(url: url)
  {
    candidates.insert(b, at: 0)
  }
  for bundle in candidates {
    #if canImport(UIKit)
    if let ui = UIImage(named: name, in: bundle, with: nil) {
      return Image(uiImage: ui)
    }
    if let url = bundle.url(forResource: name, withExtension: "png", subdirectory: subdir),
      let data = try? Data(contentsOf: url),
      let ui = UIImage(data: data)
    {
      return Image(uiImage: ui)
    }
    if let url = bundle.url(forResource: name, withExtension: "png"),
      let data = try? Data(contentsOf: url),
      let ui = UIImage(data: data)
    {
      return Image(uiImage: ui)
    }
    #elseif canImport(AppKit)
    if let url = bundle.url(forResource: name, withExtension: "png", subdirectory: subdir)
      ?? bundle.url(forResource: name, withExtension: "png"),
      let ns = NSImage(contentsOf: url)
    {
      return Image(nsImage: ns)
    }
    #endif
  }
  return nil
}

// MARK: - Icon cell

struct AppIconCell: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId
  let badge: Int
  var showLabel: Bool = true

  var body: some View {
    VStack(spacing: theme.icon.labelSpacing) {
      ZStack(alignment: .topTrailing) {
        AppGlyph(appId: appId)
          .frame(width: theme.icon.size, height: theme.icon.size)
          .shadow(
            color: theme.palette.primaryText.color.opacity(0.12),
            radius: 0.5,
            y: 0.5
          )
          .shadow(
            color: theme.palette.primaryText.color.opacity(0.22),
            radius: 7,
            y: 3
          )

        if badge > 0 {
          Text(badge > 99 ? "99+" : "\(badge)")
            .font(theme.fonts.captionFont)
            .fontWeight(.bold)
            .foregroundStyle(theme.palette.badgeText.color)
            .padding(.horizontal, badge > 9 ? 4.5 : 5.5)
            .frame(minWidth: 18, minHeight: 18)
            .background(theme.palette.badge.color, in: Capsule())
            .offset(x: 5, y: -4)
        }
      }

      if showLabel {
        Text(appId.title)
          .font(theme.fonts.iconLabelFont)
          .fontWeight(.regular)
          .foregroundStyle(theme.palette.iconLabel.color)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
          .shadow(
            color: theme.palette.primaryText.color.opacity(0.4),
            radius: 0,
            y: 0.5
          )
          .frame(width: theme.icon.size + 18)
      }
    }
  }
}

// MARK: - Glyphs

struct AppGlyph: View {
  @Environment(\.carveTheme) private var theme
  let appId: PhoneAppId

  var body: some View {
    Group {
      if appId == .calendar {
        LiveCalendarIcon()
      } else if appId == .clock {
        LiveClockIcon()
      } else if let asset = AppIconAsset.image(for: appId) {
        asset
          .resizable()
          .interpolation(.high)
          .scaledToFit()
      } else {
        fallbackGlyph
      }
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var fallbackGlyph: some View {
    ZStack {
      RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
        .fill(theme.palette.accent.color)
      Image(systemName: "app.fill")
        .font(theme.fonts.font(theme.icon.size * 0.42))
        .foregroundStyle(theme.palette.badgeText.color)
    }
  }
}

// MARK: - Live Calendar

struct LiveCalendarIcon: View {
  @Environment(\.carveTheme) private var theme

  private var weekday: String {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f.string(from: Date()).uppercased()
  }

  private var day: String {
    let f = DateFormatter()
    f.dateFormat = "d"
    return f.string(from: Date())
  }

  var body: some View {
    VStack(spacing: 0) {
      Text(weekday)
        .font(theme.fonts.font(10))
        .fontWeight(.bold)
        .tracking(0.4)
        .foregroundStyle(theme.palette.badgeText.color)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(theme.palette.destructive.color)
      Text(day)
        .font(theme.fonts.font(34))
        .fontWeight(.light)
        .foregroundStyle(theme.palette.primaryText.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.palette.elevatedBackground.color)
    }
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous))
  }
}

// MARK: - Live Clock

struct LiveClockIcon: View {
  @Environment(\.carveTheme) private var theme

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      let cal = Calendar.current
      let h = cal.component(.hour, from: context.date) % 12
      let m = cal.component(.minute, from: context.date)
      let s = cal.component(.second, from: context.date)
      let hourAngle = Angle.degrees(Double(h) * 30 + Double(m) * 0.5 - 90)
      let minuteAngle = Angle.degrees(Double(m) * 6 - 90)
      let secondAngle = Angle.degrees(Double(s) * 6 - 90)

      ZStack {
        RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
          .fill(theme.palette.primaryText.color)
        Circle()
          .fill(theme.palette.elevatedBackground.color)
          .padding(7)
        ForEach(0..<12, id: \.self) { i in
          Capsule()
            .fill(theme.palette.primaryText.color.opacity(0.75))
            .frame(width: 1.4, height: i % 3 == 0 ? 5 : 3.2)
            .offset(y: -(theme.icon.size * 0.33))
            .rotationEffect(.degrees(Double(i) * 30))
        }
        Capsule()
          .fill(theme.palette.primaryText.color)
          .frame(width: 2.8, height: theme.icon.size * 0.17)
          .offset(y: -(theme.icon.size * 0.085))
          .rotationEffect(hourAngle)
        Capsule()
          .fill(theme.palette.primaryText.color)
          .frame(width: 2.0, height: theme.icon.size * 0.25)
          .offset(y: -(theme.icon.size * 0.125))
          .rotationEffect(minuteAngle)
        Capsule()
          .fill(theme.palette.destructive.color)
          .frame(width: 1.1, height: theme.icon.size * 0.27)
          .offset(y: -(theme.icon.size * 0.11))
          .rotationEffect(secondAngle)
        Circle()
          .fill(theme.palette.primaryText.color)
          .frame(width: 3.5, height: 3.5)
      }
    }
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
