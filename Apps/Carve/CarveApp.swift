// Apps/Carve/CarveApp.swift
import SwiftUI
import CarveCore
import CarveShell
import CarveUI

@main
struct CarveApp: App {
  /// Owns the load outcome. On success, holds the `GameSession` the UI observes
  /// via `environmentObject` (so session mutations still publish correctly).
  @StateObject private var bootstrap: AppBootstrap

  init() {
    _bootstrap = StateObject(wrappedValue: AppBootstrap(caseId: "five_minutes"))
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch bootstrap.phase {
        case .loading:
          PhoneLaunchView(theme: Theme.iosLookalike)
            .accessibilityIdentifier("launch-loading")
        case .ready(let session):
          RootPhoneView()
            .environmentObject(session)
            .environment(\.carveTheme, session.theme)
            .accessibilityIdentifier("phone-root")
        case .failed(let message):
          CaseLoadFailureView(message: message)
            .accessibilityIdentifier("case-load-failure")
        }
      }
    }
  }
}

/// Loads the case once at launch, restores a compatible snapshot, and wires
/// auto-save. Failures stay failures — no empty fake case.
@MainActor
public final class AppBootstrap: ObservableObject {
  public enum Phase {
    case loading
    case ready(GameSession)
    case failed(String)
  }

  @Published public private(set) var phase: Phase = .loading

  private let caseId: String
  private let store: SessionStore
  private var session: GameSession?

  public init(
    caseId: String,
    store: SessionStore? = nil,
    autoStart: Bool = true
  ) {
    self.caseId = caseId
    if let store {
      self.store = store
    } else {
      let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent("Carve", isDirectory: true)
        ?? FileManager.default.temporaryDirectory.appendingPathComponent("Carve", isDirectory: true)
      self.store = FileSessionStore(directory: dir)
    }
    if autoStart {
      start()
    }
  }

  public func start() {
    do {
      let args = ProcessInfo.processInfo.arguments
      if args.contains("-resetProgress") {
        try? store.clear()
      }

      guard let dir = CaseBundleLoader.resolveCaseDirectory(id: caseId) else {
        throw CaseBundleLoaderError.missingManifest(
          "Cases/\(caseId)/case.json (not in bundle or cwd)")
      }
      let caseFile = try CaseBundleLoader.load(directory: dir)
      guard !caseFile.fragments.isEmpty else {
        throw SessionPersistenceError.emptyCase
      }

      let session: GameSession
      if args.contains("-uiTestSkipRestore") {
        session = GameSession(caseFile: caseFile)
      } else if let snapshot = try store.load() {
        do {
          session = try GameSession(caseFile: caseFile, snapshot: snapshot)
        } catch {
          // Incompatible / corrupt progress is visible, not silently wiped to empty.
          phase = .failed(String(describing: error))
          return
        }
      } else {
        session = GameSession(caseFile: caseFile)
      }

      session.onMutation = { [weak self] s in
        try? self?.store.save(s.makeSnapshot())
      }
      self.session = session
      phase = .ready(session)
    } catch {
      phase = .failed(String(describing: error))
    }
  }

  /// Developer reset: wipe snapshot and reload a fresh session.
  public func resetProgress() {
    try? store.clear()
    session = nil
    phase = .loading
    start()
  }
}

/// Phone-shell-matched launch chrome so cold start never flashes raw white.
public struct PhoneLaunchView: View {
  let theme: Theme

  public init(theme: Theme) {
    self.theme = theme
  }

  public var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          theme.palette.homeWallpaperTop.color,
          theme.palette.homeWallpaperBottom.color,
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: theme.spacing.md) {
        RoundedRectangle(cornerRadius: theme.radii.appIcon, style: .continuous)
          .fill(theme.palette.elevatedBackground.color.opacity(0.18))
          .frame(width: theme.icon.size * 1.4, height: theme.icon.size * 1.4)
          .overlay {
            Image(systemName: "lock.open.fill")
              .font(theme.fonts.font(28))
              .foregroundStyle(theme.palette.badgeText.color.opacity(0.9))
          }
        Text("Unlocking…")
          .font(theme.fonts.subheadlineFont)
          .foregroundStyle(theme.palette.badgeText.color.opacity(0.85))
      }
    }
    .environment(\.carveTheme, theme)
  }
}
