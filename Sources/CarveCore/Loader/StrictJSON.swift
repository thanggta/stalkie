// Sources/CarveCore/Loader/StrictJSON.swift
import Foundation

/// A case authoring toolchain that accepts permissive JSON is a trap: a
/// `case.json` with a trailing comma or a duplicate key validates and ships,
/// and the player sees whichever decoding arbitrarily kept. Foundation's
/// JSONDecoder tolerates trailing commas, so "CarveCLI passed" did not mean
/// "the JSON is valid". This is the strictness check that closes that gap.
///
/// It validates the two silent-authoring-error shapes the lenient parser
/// accepts — trailing commas and duplicate object keys — and reports syntax
/// errors with a character position. Everything else stays the domain of
/// JSONDecoder, which is already strict about malformed structure.
public enum StrictJSONError: Error, Equatable {
  case trailingCommaAt(Int)
  case duplicateKeyAt(Int, key: String)
  case syntaxErrorAt(Int, detail: String)
}

public func validateStrictJSON(_ data: Data) throws {
  guard let text = String(data: data, encoding: .utf8) else {
    throw StrictJSONError.syntaxErrorAt(0, detail: "not valid UTF-8")
  }
  var parser = StrictJSONParser(TextCursor(text))
  try parser.parseValue()
  try parser.expectEnd()
}

// MARK: - Parser

/// Recursive-descent walk over the JSON grammar. It builds no tree; it exists
/// only to find the two leniency hazards and to bound the walk so the "end"
/// check is meaningful.
struct StrictJSONParser {
  private var cursor: TextCursor

  init(_ cursor: TextCursor) {
    self.cursor = cursor
  }

  mutating func expectEnd() throws {
    try cursor.skipWhitespace()
    guard cursor.isAtEnd else {
      throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "trailing content after JSON value")
    }
  }

  mutating func parseValue() throws {
    try cursor.skipWhitespace()
    guard let ch = cursor.peek() else {
      throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "unexpected end of input")
    }
    switch ch {
    case "{": try parseObject()
    case "[": try parseArray()
    case "\"": _ = try cursor.parseString()
    case "t", "f", "n": try parseLiteral()
    case "-", "0"..."9": try parseNumber()
    default:
      throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected a JSON value")
    }
  }

  private mutating func parseObject() throws {
    _ = cursor.advance() // consume "{"
    var keys = Set<String>()
    // True once a comma has been consumed: the next token must be a key, and
    // a '}' here is a trailing comma.
    var afterComma = false
    while true {
      try cursor.skipWhitespace()
      guard let ch = cursor.peek() else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "unterminated object")
      }
      if ch == "}" {
        if afterComma {
          throw StrictJSONError.trailingCommaAt(cursor.index)
        }
        _ = cursor.advance()
        return
      }
      afterComma = false
      guard ch == "\"" else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "object keys must be quoted strings")
      }
      let key = try cursor.parseString()
      if keys.contains(key) {
        throw StrictJSONError.duplicateKeyAt(cursor.index, key: key)
      }
      keys.insert(key)
      try cursor.skipWhitespace()
      guard cursor.peek() == ":" else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected ':' after object key")
      }
      _ = cursor.advance()
      try parseValue()
      try cursor.skipWhitespace()
      if cursor.peek() == "," {
        _ = cursor.advance()
        afterComma = true
      } else if cursor.peek() == "}" {
        afterComma = false
      } else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected ',' or '}' in object")
      }
    }
  }

  private mutating func parseArray() throws {
    _ = cursor.advance() // consume "["
    var afterComma = false
    while true {
      try cursor.skipWhitespace()
      guard let ch = cursor.peek() else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "unterminated array")
      }
      if ch == "]" {
        if afterComma {
          throw StrictJSONError.trailingCommaAt(cursor.index)
        }
        _ = cursor.advance()
        return
      }
      afterComma = false
      try parseValue()
      try cursor.skipWhitespace()
      if cursor.peek() == "," {
        _ = cursor.advance()
        afterComma = true
      } else if cursor.peek() == "]" {
        afterComma = false
      } else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected ',' or ']' in array")
      }
    }
  }

  private mutating func parseLiteral() throws {
    for literal in ["true", "false", "null"] where cursor.hasPrefix(literal) {
      cursor.advance(by: literal.unicodeScalars.count)
      return
    }
    throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "invalid literal")
  }

  private mutating func parseNumber() throws {
    if cursor.peek() == "-" { cursor.advance() }
    // Integer part.
    if cursor.peek() == "0" {
      cursor.advance()
    } else if isDigit(cursor.peek()) {
      while isDigit(cursor.peek()) { cursor.advance() }
    } else {
      throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "invalid number")
    }
    // Fraction.
    if cursor.peek() == "." {
      cursor.advance()
      guard isDigit(cursor.peek()) else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected digits after '.'")
      }
      while isDigit(cursor.peek()) { cursor.advance() }
    }
    // Exponent.
    if cursor.peek() == "e" || cursor.peek() == "E" {
      cursor.advance()
      if cursor.peek() == "+" || cursor.peek() == "-" { cursor.advance() }
      guard isDigit(cursor.peek()) else {
        throw StrictJSONError.syntaxErrorAt(cursor.index, detail: "expected digits in exponent")
      }
      while isDigit(cursor.peek()) { cursor.advance() }
    }
  }
}

private func isDigit(_ ch: Character?) -> Bool {
  guard let ch, ("0"..."9").contains(ch) else { return false }
  return true
}

// MARK: - Cursor

struct TextCursor {
  private let scalars: [Unicode.Scalar]
  private(set) var index = 0

  init(_ text: String) {
    scalars = Array(text.unicodeScalars)
  }

  var isAtEnd: Bool { index >= scalars.count }

  /// Returns nil at end of input so a `peek()` can never index out of range.
  func peek() -> Character? {
    guard !isAtEnd else { return nil }
    return Character(scalars[index])
  }

  mutating func advance() {
    index += 1
  }

  mutating func advance(by count: Int) {
    index = min(index + count, scalars.count)
  }

  func hasPrefix(_ literal: String) -> Bool {
    let literalScalars = Array(literal.unicodeScalars)
    guard index + literalScalars.count <= scalars.count else { return false }
    for (i, scalar) in literalScalars.enumerated() where scalars[index + i] != scalar {
      return false
    }
    return true
  }

  mutating func skipWhitespace() throws {
    while let scalar = peek() {
      switch scalar {
      case " ", "\t", "\n", "\r": index += 1
      default: return
      }
    }
  }

  /// Parses a `"..."` string including escapes. Returns the decoded content.
  mutating func parseString() throws -> String {
    guard peek() == "\"" else {
      throw StrictJSONError.syntaxErrorAt(index, detail: "expected '\"'")
    }
    index += 1 // consume opening quote
    var decoded = String.UnicodeScalarView()
    while true {
      guard let scalar = peek() else {
        throw StrictJSONError.syntaxErrorAt(index, detail: "unterminated string")
      }
      switch scalar {
      case "\"":
        index += 1
        return String(decoded)
      case "\\":
        index += 1
        guard let escape = peek() else {
          throw StrictJSONError.syntaxErrorAt(index, detail: "unterminated escape")
        }
        index += 1
        switch escape {
        case "\"": decoded.append("\u{22}")
        case "\\": decoded.append("\u{5C}")
        case "/": decoded.append("\u{2F}")
        case "b": decoded.append("\u{08}")
        case "f": decoded.append("\u{0C}")
        case "n": decoded.append("\n")
        case "r": decoded.append("\r")
        case "t": decoded.append("\t")
        case "u":
          guard index + 4 <= scalars.count else {
            throw StrictJSONError.syntaxErrorAt(index, detail: "truncated \\u escape")
          }
          let hex = String(scalars[index ..< index + 4].map(Character.init))
          guard let code = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(code) else {
            throw StrictJSONError.syntaxErrorAt(index, detail: "invalid \\u escape")
          }
          decoded.append(scalar)
          index += 4
        default:
          throw StrictJSONError.syntaxErrorAt(index - 1, detail: "invalid escape sequence")
        }
      default:
        decoded.append(scalar.unicodeScalars.first!)
        index += 1
      }
    }
  }
}
