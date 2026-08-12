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
      if let session = bootstrap.session {
        RootPhoneView()
          .environmentObject(session)
          .environment(\.carveTheme, session.theme)
      } else {
        CaseLoadFailureView(message: bootstrap.failureMessage)
      }
    }
  }
}

/// Loads the case once at launch. Failures stay failures — no empty fake case.
public final class AppBootstrap: ObservableObject {
  public let session: GameSession?
  public let failureMessage: String

  public init(caseId: String) {
    do {
      guard let dir = CaseBundleLoader.resolveCaseDirectory(id: caseId) else {
        throw CaseBundleLoaderError.missingManifest("Cases/\(caseId)/case.json (not in bundle or cwd)")
      }
      let caseFile = try CaseBundleLoader.load(directory: dir)
      self.session = GameSession(caseFile: caseFile)
      self.failureMessage = ""
    } catch {
      self.session = nil
      self.failureMessage = String(describing: error)
    }
  }
}
