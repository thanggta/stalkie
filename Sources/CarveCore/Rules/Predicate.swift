public struct PredicateFormatError: Error, Equatable, CustomStringConvertible {
  public let message: String
  public init(_ message: String) {
    self.message = message
  }
  public var description: String { message }
}

public struct GameState: Equatable, Sendable {
  public let carvedFragmentIds: Set<String>
  /// Canonical form: two entity ids sorted and joined with '|'.
  public let linkedPairs: Set<String>
  public let answeredQuestionIds: Set<String>

  public static func linkKey(_ a: String, _ b: String) -> String {
    let pair = [a, b].sorted()
    return "\(pair[0])|\(pair[1])"
  }

  // FIX A: canonical form only. The read path must accept exactly what
  // `linkKey` produces; raw orderings are never valid, or the
  // canonicalization contract becomes unenforceable.
  public func hasLink(_ a: String, _ b: String) -> Bool {
    linkedPairs.contains(Self.linkKey(a, b))
  }
}

public protocol Predicate: Sendable {
  func evaluate(_ state: GameState) -> Bool
}

public struct CarvedPredicate: Predicate {
  public let fragmentId: String
  public func evaluate(_ state: GameState) -> Bool {
    state.carvedFragmentIds.contains(fragmentId)
  }
}

public struct LinkedPredicate: Predicate {
  public let a: String
  public let b: String
  public func evaluate(_ state: GameState) -> Bool {
    state.hasLink(a, b)
  }
}

public struct AnsweredPredicate: Predicate {
  public let questionId: String
  public func evaluate(_ state: GameState) -> Bool {
    state.answeredQuestionIds.contains(questionId)
  }
}

public struct AllPredicate: Predicate {
  public let children: [any Predicate]
  public func evaluate(_ state: GameState) -> Bool {
    children.allSatisfy { $0.evaluate(state) }
  }
}

public struct AnyPredicate: Predicate {
  public let children: [any Predicate]
  public func evaluate(_ state: GameState) -> Bool {
    children.contains { $0.evaluate(state) }
  }
}

public struct NotPredicate: Predicate {
  public let child: any Predicate
  public func evaluate(_ state: GameState) -> Bool {
    !child.evaluate(state)
  }
}

/// The complete grammar. Adding a key requires a decision record in the design
/// spec (INV-5).
private let allowedPredicateKeys: Set<String> = [
  "carved", "linked", "answered", "all", "any", "not",
]

// FIX B: entirely cast-free. `guard case .string(...) = value` pattern matching
// only — a malformed element throws `PredicateFormatError`, never crashes.
public func parsePredicate(_ object: [String: JSONValue]) throws -> any Predicate {
  guard let (key, value) = object.first, object.count == 1 else {
    throw PredicateFormatError("A predicate must have exactly one key, got \(Array(object.keys))")
  }
  guard allowedPredicateKeys.contains(key) else {
    throw PredicateFormatError(
      "Unknown predicate \"\(key)\". Allowed: carved, linked, answered, all, any, not. "
        + "Expression strings and script references are not supported (INV-5).")
  }

  switch key {
  case "carved":
    guard case .string(let fragmentId) = value else {
      throw PredicateFormatError("\"carved\" needs a fragment id string")
    }
    return CarvedPredicate(fragmentId: fragmentId)
  case "answered":
    guard case .string(let questionId) = value else {
      throw PredicateFormatError("\"answered\" needs a question id string")
    }
    return AnsweredPredicate(questionId: questionId)
  case "linked":
    guard case .array(let elements) = value,
      elements.count == 2,
      case .string(let a) = elements[0],
      case .string(let b) = elements[1]
    else {
      throw PredicateFormatError("\"linked\" needs exactly two entity ids")
    }
    return LinkedPredicate(a: a, b: b)
  case "all", "any":
    guard case .array(let elements) = value, !elements.isEmpty else {
      throw PredicateFormatError("\"\(key)\" needs a non-empty list")
    }
    var children: [any Predicate] = []
    children.reserveCapacity(elements.count)
    for element in elements {
      guard case .object(let childObject) = element else {
        throw PredicateFormatError("\"\(key)\" children must be predicate objects")
      }
      children.append(try parsePredicate(childObject))
    }
    if key == "all" {
      return AllPredicate(children: children)
    }
    return AnyPredicate(children: children)
  case "not":
    guard case .object(let childObject) = value else {
      throw PredicateFormatError("\"not\" needs a predicate object")
    }
    return NotPredicate(child: try parsePredicate(childObject))
  default:
    throw PredicateFormatError("Unreachable")
  }
}
