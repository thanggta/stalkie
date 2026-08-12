// Sources/CarveUI/AppBootstrap.swift
// Composition root: catalog + entitlement + case launcher.
// Views never verify purchases.

import Combine
import Foundation
import CarveCommerce
import CarveCore
import CarveShell

@MainActor
public final class AppBootstrap: ObservableObject {
  public enum Phase {
    case loading
    case library
    case phone(GameSession)
    case purchase(CatalogEntry)
    case pickCase([String])
    case failed(String)
  }

  @Published public private(set) var phase: Phase = .loading
  @Published public private(set) var purchasePhase: PurchasePhase = .idle
  @Published public private(set) var catalog: CaseCatalog
  public let entitlements: any EntitlementProviding

  private let arguments: [String]
  private let supportDirectory: URL
  private var session: GameSession?
  private var entitlementWatcher: AnyCancellable?

  public static var developerToolsEnabled: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
  }

  public init(
    arguments: [String] = ProcessInfo.processInfo.arguments,
    catalog: CaseCatalog? = nil,
    entitlements: (any EntitlementProviding)? = nil,
    supportDirectory: URL? = nil,
    autoStart: Bool = true
  ) {
    self.arguments = arguments
    self.supportDirectory =
      supportDirectory
      ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?
      .appendingPathComponent("Carve", isDirectory: true)
      ?? FileManager.default.temporaryDirectory.appendingPathComponent("Carve", isDirectory: true)

    let resolvedCatalog =
      catalog ?? (try? CatalogLoader.load()) ?? CaseCatalog(schemaVersion: 1, entries: [])
    self.catalog = resolvedCatalog
    let resolvedEntitlements =
      entitlements ?? StoreKitEntitlementStore(productIds: resolvedCatalog.paidProductIds)
    self.entitlements = resolvedEntitlements

    if let fake = resolvedEntitlements as? FakeEntitlementProvider {
      entitlementWatcher = fake.objectWillChange.sink { [weak self] _ in
        self?.objectWillChange.send()
      }
    }

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

    phase = .library
    Task { await entitlements.refresh() }

    if arguments.contains("-resetProgress") {
      try? CaseProgressStore.clearAll(in: supportDirectory)
    }

    // Always re-resolve the catalog from disk/bundle at start so the
    // simulator app sees Cases/catalog.json after the copy phase.
    if let loaded = try? CatalogLoader.load() {
      catalog = loaded
    }

    if let requested = explicitLaunchCaseId() {
      openCase(requested)
    }
  }

  public func canLaunch(_ entry: CatalogEntry) -> Bool {
    CaseLaunchAccess.canLaunch(
      catalog: catalog,
      caseId: entry.caseId,
      snapshot: entitlements.snapshot,
      arguments: arguments)
  }

  public func progress(for caseId: String) -> CaseProgress {
    CaseProgressStore.progress(for: caseId, in: supportDirectory)
  }

  public func showPurchase(_ entry: CatalogEntry) {
    guard entry.access == .paid else { return }
    if let productId = entry.productId,
      entitlements.snapshot.status(for: productId) == .revoked
    {
      purchasePhase = .revoked
    } else {
      purchasePhase = .idle
    }
    phase = .purchase(entry)
  }

  public func openCase(_ id: String) {
    guard CaseLaunchAccess.canLaunch(
      catalog: catalog,
      caseId: id,
      snapshot: entitlements.snapshot,
      arguments: arguments)
    else {
      if let entry = catalog.entry(id: id), entry.access == .paid {
        showPurchase(entry)
      } else if catalog.entry(id: id) == nil {
        phase = .failed(PlayerFacingCopy.loadFailedBody)
      }
      return
    }
    load(caseId: id, reset: false)
  }

  public func replay(_ id: String) {
    guard CaseLaunchAccess.canLaunch(
      catalog: catalog,
      caseId: id,
      snapshot: entitlements.snapshot,
      arguments: arguments)
    else { return }
    try? CaseProgressStore.clear(caseId: id, in: supportDirectory)
    load(caseId: id, reset: true)
  }

  public func returnToLibrary() {
    session = nil
    purchasePhase = .idle
    phase = .library
    objectWillChange.send()
  }

  public func buy(_ entry: CatalogEntry) async {
    guard let productId = entry.productId else { return }
    purchasePhase = .purchasing
    let outcome = await entitlements.purchase(productId: productId)
    switch outcome {
    case .purchased:
      purchasePhase = .purchased
      openCase(entry.caseId)
    case .cancelled:
      purchasePhase = .cancelled
    case .pending:
      purchasePhase = .pending
    case .unverified:
      purchasePhase = .failed("This purchase could not be verified. The case stays locked.")
    case .failed(let message):
      purchasePhase = .failed(message)
    case .unavailable:
      purchasePhase = .unavailable
    }
  }

  public func restorePurchases() async {
    _ = await entitlements.restorePurchases()
    objectWillChange.send()
    if case .purchase(let entry) = phase,
      CaseLaunchAccess.canLaunch(
        catalog: catalog,
        caseId: entry.caseId,
        snapshot: entitlements.snapshot,
        arguments: arguments)
    {
      purchasePhase = .purchased
      openCase(entry.caseId)
    }
  }

  public func deleteAllProgress() {
    try? CaseProgressStore.clearAll(in: supportDirectory)
    session = nil
    phase = .library
    objectWillChange.send()
  }

  public func resetProgress() {
    #if DEBUG
    try? CaseProgressStore.clearAll(in: supportDirectory)
    session = nil
    phase = .library
    #endif
  }

  private func explicitLaunchCaseId() -> String? {
    let resolved = CaseLaunch.resolvedCaseId(arguments: arguments, default: "")
    return resolved.isEmpty ? nil : resolved
  }

  private func load(caseId: String, reset: Bool) {
    do {
      guard let dir = CaseBundleLoader.resolveCaseDirectory(id: caseId) else {
        throw CaseBundleLoaderError.missingManifest(
          "Cases/\(caseId)/case.json (not in bundle or cwd)")
      }
      let caseFile = try CaseBundleLoader.load(directory: dir)
      guard !caseFile.fragments.isEmpty else {
        throw SessionPersistenceError.emptyCase
      }

      let store = FileSessionStore(directory: supportDirectory, caseId: caseId)
      if reset {
        try? store.clear()
      }

      let session: GameSession
      if arguments.contains("-uiTestSkipRestore") || reset {
        session = GameSession(caseFile: caseFile)
      } else if let snapshot = try store.load() {
        do {
          session = try GameSession(caseFile: caseFile, snapshot: snapshot)
        } catch {
          phase = .failed(playerFacingLoadMessage(error))
          return
        }
      } else {
        session = GameSession(caseFile: caseFile)
      }

      SessionPersistence.attach(store: store, to: session)
      self.session = session
      phase = .phone(session)
    } catch {
      phase = .failed(playerFacingLoadMessage(error))
    }
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
