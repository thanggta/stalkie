// Sources/CarveShell/Session/PlayerFacingCopy.swift
// Production-facing language stays in the phone, not the engine.
// Developer detail is kept separately for debug / logs.

import Foundation

public enum PlayerFacingCopy {
  public static let saveFailed =
    "This phone couldn't keep what you just found. You can keep looking, but if you leave now you may lose it."

  public static let saveFailedRetry = "Try again"

  public static let loadFailedTitle = "This phone won't open"

  public static let loadFailedBody =
    "Something on it is unreadable. This isn't an empty phone — it couldn't start."

  public static let imageMissing = "This photo couldn't be opened."

  public static let imageRecovering = "Opening…"

  /// Words the player should never see. Used by tests and by debug filtering.
  public static let engineVocabulary: [String] = [
    "fragment",
    "carve",
    "sector",
    "predicate",
    "damage seed",
    "schema",
  ]

  public static func containsEngineVocabulary(_ text: String) -> Bool {
    let lower = text.lowercased()
    return engineVocabulary.contains { lower.contains($0) }
  }

  public static func loadFailure(from error: Error) -> PersistenceFailure {
    PersistenceFailure(
      playerMessage: loadFailedBody,
      developerDetail: String(describing: error))
  }
}

/// A failed IO action the player can see without being handed engine jargon.
public struct PersistenceFailure: Equatable, Sendable {
  public let playerMessage: String
  public let developerDetail: String

  public init(playerMessage: String, developerDetail: String) {
    self.playerMessage = playerMessage
    self.developerDetail = developerDetail
  }

  public init(error: Error) {
    self.playerMessage = PlayerFacingCopy.saveFailed
    self.developerDetail = String(describing: error)
  }
}

/// Wires a SessionStore to GameSession so save failures become session state.
/// IO stays in this module — never in CarveCore.
public enum SessionPersistence {
  public static func attach(store: SessionStore, to session: GameSession) {
    session.onMutation = { [weak store] s in
      guard let store else { return }
      do {
        try store.save(s.makeSnapshot())
        s.clearPersistenceFailure()
      } catch {
        s.recordPersistenceFailure(PersistenceFailure(error: error))
      }
    }
  }
}
