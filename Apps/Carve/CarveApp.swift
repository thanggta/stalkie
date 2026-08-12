// Apps/Carve/CarveApp.swift
import SwiftUI
import CarveCore
import CarveShell
import CarveUI

@main
struct CarveApp: App {
  @StateObject private var session: GameSession

  init() {
    let caseFile: CaseFile
    if let dir = CaseBundleLoader.resolveCaseDirectory(id: "five_minutes"),
      let loaded = try? CaseBundleLoader.load(directory: dir)
    {
      caseFile = loaded
    } else {
      caseFile = CaseFile(
        schemaVersion: 1,
        id: "missing",
        title: "Missing case",
        sectorMap: [],
        questions: [],
        fragments: [:])
    }
    _session = StateObject(wrappedValue: GameSession(caseFile: caseFile))
  }

  var body: some Scene {
    WindowGroup {
      RootPhoneView()
        .environmentObject(session)
        .environment(\.carveTheme, session.theme)
    }
  }
}
