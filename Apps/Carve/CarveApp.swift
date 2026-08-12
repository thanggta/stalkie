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
    _bootstrap = StateObject(wrappedValue: AppBootstrap())
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch bootstrap.phase {
        case .loading:
          PhoneLaunchView(theme: Theme.iosLookalike)
            .accessibilityIdentifier("launch-loading")
        case .pickCase(let ids):
          DebugCasePickerView(ids: ids) { id in
            bootstrap.selectCase(id)
          }
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
    case pickCase([String])
    case ready(GameSession)
    case failed(String)
  }

  @Published public private(set) var phase: Phase = .loading

  private let arguments: [String]
  private let supportDirectory: URL
  private let injectedStore: SessionStore?
  private var store: SessionStore
  private var caseId: String
  private var session: GameSession?

  public init(
    arguments: [String] = ProcessInfo.processInfo.arguments,
    store: SessionStore? = nil,
    autoStart: Bool = true
  ) {
    self.arguments = arguments
    self.injectedStore = store
    self.supportDirectory =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?
      .appendingPathComponent("Carve", isDirectory: true)
      ?? FileManager.default.temporaryDirectory.appendingPathComponent("Carve", isDirectory: true)
    self.caseId = CaseLaunch.resolvedCaseId(arguments: arguments)
    self.store = store ?? FileSessionStore(directory: supportDirectory, caseId: caseId)
    if autoStart {
      start()
    }
  }

  public func start() {
    #if DEBUG
    if CaseLaunch.shouldShowPicker(arguments: arguments) {
      phase = .pickCase(CaseLaunch.discoverBundledCaseIds())
      return
    }
    #endif
    load(caseId: caseId)
  }

  public func selectCase(_ id: String) {
    load(caseId: id)
  }

  private func load(caseId: String) {
    self.caseId = caseId
    if injectedStore == nil {
      store = FileSessionStore(directory: supportDirectory, caseId: caseId)
    }
    do {
      if arguments.contains("-resetProgress") {
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
      if arguments.contains("-uiTestSkipRestore") {
        session = GameSession(caseFile: caseFile)
      } else if let snapshot = try store.load() {
        do {
          session = try GameSession(caseFile: caseFile, snapshot: snapshot)
        } catch {
          // Incompatible / corrupt progress is visible, not silently wiped to empty.
          phase = .failed(playerFacingLoadMessage(error))
          return
        }
      } else {
        session = GameSession(caseFile: caseFile)
      }

      SessionPersistence.attach(store: store, to: session)
      self.session = session
      phase = .ready(session)
    } catch {
      phase = .failed(playerFacingLoadMessage(error))
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

private func playerFacingLoadMessage(_ error: Error) -> String {
  let failure = PlayerFacingCopy.loadFailure(from: error)
  #if DEBUG
  return failure.playerMessage + "\n\n" + failure.developerDetail
  #else
  return failure.playerMessage
  #endif
}

struct DebugCasePickerView: View {
  let ids: [String]
  let onSelect: (String) -> Void
  private let theme = Theme.iosLookalike

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("Choose a phone")
        .font(theme.fonts.titleFont)
        .foregroundStyle(theme.palette.primaryText.color)
      Text("Development only. Production opens the default case.")
        .font(theme.fonts.subheadlineFont)
        .foregroundStyle(theme.palette.secondaryText.color)

      if ids.isEmpty {
        Text("No cases were found in the bundle.")
          .font(theme.fonts.bodyFont)
          .foregroundStyle(theme.palette.destructive.color)
      } else {
        ForEach(ids, id: \.self) { id in
          Button {
            onSelect(id)
          } label: {
            Text(id.replacingOccurrences(of: "_", with: " "))
              .font(theme.fonts.headlineFont)
              .foregroundStyle(theme.palette.badgeText.color)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(theme.spacing.md)
              .background(
                theme.palette.elevatedBackground.color,
                in: RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
              )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("case-pick-\(id)")
        }
      }
      Spacer()
    }
    .padding(theme.spacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(theme.palette.screenBackground.color.ignoresSafeArea())
    .environment(\.carveTheme, theme)
    .accessibilityIdentifier("case-picker")
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
