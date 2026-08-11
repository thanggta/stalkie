import Foundation

public struct CaseFormatError: Error, Equatable, CustomStringConvertible {
  public let message: String
  public init(_ message: String) {
    self.message = message
  }
  public var description: String { message }
}

public func parseCase(
  manifestData: Data,
  fragmentFiles: [(name: String, data: Data)]
) throws -> CaseFile {
  try rejectFloatSchemaVersion(manifestData)

  let decoder = JSONDecoder()
  let manifest: CaseManifest
  do {
    manifest = try decoder.decode(CaseManifest.self, from: manifestData)
  } catch let error as DecodingError {
    throw CaseFormatError("case.json: \(decodeErrorText(error))")
  }

  guard manifest.schemaVersion == 1 else {
    throw CaseFormatError(
      "Unsupported schemaVersion \"\(manifest.schemaVersion)\". This build supports 1 only.")
  }

  let sectorMap = try manifest.sectorMap.map { wire in
    SectorEntry(
      fragmentId: wire.fragmentId,
      typeHint: try parseType(wire.typeHint, fragmentId: wire.fragmentId),
      integrity: wire.integrity,
      carveCost: wire.carveCost)
  }

  let questions = manifest.verdict.questions

  var fragments: [String: Fragment] = [:]
  for file in fragmentFiles {
    let fallbackID = file.name.hasSuffix(".json") ? String(file.name.dropLast(5)) : file.name
    let probe = try? decoder.decode(FragmentIDProbe.self, from: file.data)
    let id = probe?.id ?? fallbackID

    let wire: FragmentWire
    do {
      wire = try decoder.decode(FragmentWire.self, from: file.data)
    } catch let error as DecodingError {
      if let seedError = missingSeedError(error, fragmentId: id) {
        throw seedError
      }
      throw CaseFormatError("Fragment \"\(id)\": \(decodeErrorText(error))")
    }

    let type = try parseType(wire.type, fragmentId: id)
    guard DamageSpec.allowedProfiles.contains(wire.damage.profile) else {
      throw CaseFormatError(
        "Fragment \"\(id)\" has unknown damage profile \"\(wire.damage.profile)\". Allowed: "
          + "block-loss, scanline-tear, partial-decode, chroma-bleed, overwrite.")
    }
    guard (0.0...1.0).contains(wire.damage.intensity) else {
      throw CaseFormatError("Fragment \"\(id)\" damage.intensity must be a number 0..1.")
    }

    fragments[id] = Fragment(
      id: id,
      type: type,
      label: wire.label,
      damage: DamageSpec(
        profile: wire.damage.profile,
        intensity: wire.damage.intensity,
        seed: wire.damage.seed),
      content: wire.content)
  }

  return CaseFile(
    schemaVersion: manifest.schemaVersion,
    id: manifest.id,
    title: manifest.title,
    cycleBudget: manifest.cycleBudget,
    sectorMap: sectorMap,
    questions: questions,
    fragments: fragments)
}

// MARK: - Wire structs

private struct FragmentIDProbe: Decodable {
  let id: String
}

private struct SectorWire: Decodable {
  let fragmentId: String
  let typeHint: String
  let integrity: Double
  let carveCost: Int
}

private struct DamageWire: Decodable {
  let profile: String
  let intensity: Double
  let seed: Int
}

private struct FragmentWire: Decodable {
  let id: String
  let type: String
  let label: String
  let damage: DamageWire
  let content: [String: JSONValue]
}

private struct VerdictWire: Decodable {
  let questions: [VerdictQuestion]
}

private struct CaseManifest: Decodable {
  let schemaVersion: Int
  let id: String
  let title: String
  let cycleBudget: Int
  let sectorMap: [SectorWire]
  let verdict: VerdictWire
}

// MARK: - Strict schemaVersion

// JSONDecoder coerces `1.0` -> 1 when decoding an Int, so the float check must
// run on the raw JSON token before Codable ever sees it.
private func rejectFloatSchemaVersion(_ manifestData: Data) throws {
  guard let object = try? JSONSerialization.jsonObject(with: manifestData) as? [String: Any],
    let schemaValue = object["schemaVersion"],
    let number = schemaValue as? NSNumber
  else {
    return
  }
  let type = CFNumberGetType(number as CFNumber)
  let floatTypes: Set<CFNumberType> = [
    .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType,
  ]
  if floatTypes.contains(type) {
    throw CaseFormatError(
      "case.json: schemaVersion must be an integer literal, got a floating-point value.")
  }
}

// MARK: - Fragment type / damage checks

private func parseType(_ raw: String, fragmentId: String) throws -> FragmentType {
  if raw == "audio" {
    throw CaseFormatError(
      "Fragment \"\(fragmentId)\" has type \"audio\", which is not supported in v1 (see DR-6). "
        + "Remove it or convert it to a note/record fragment.")
  }
  switch raw {
  case "thread": return .thread
  case "image": return .image
  case "record": return .record
  case "note": return .note
  default:
    throw CaseFormatError(
      "Fragment \"\(fragmentId)\" has unknown type \"\(raw)\". Allowed: thread, image, record, note.")
  }
}

private func missingSeedError(_ error: DecodingError, fragmentId: String) -> CaseFormatError? {
  switch error {
  case .keyNotFound(let key, _) where key.stringValue == "seed":
    return CaseFormatError(
      "Fragment \"\(fragmentId)\" is missing damage.seed. Damage must be deterministic so "
        + "screenshots and bug reports reproduce.")
  case .valueNotFound(_, let context) where context.codingPath.contains(where: { $0.stringValue == "seed" }):
    return CaseFormatError(
      "Fragment \"\(fragmentId)\" is missing damage.seed. Damage must be deterministic so "
        + "screenshots and bug reports reproduce.")
  default:
    return nil
  }
}

// MARK: - DecodingError to text

private func decodeErrorText(_ error: DecodingError) -> String {
  switch error {
  case .keyNotFound(let key, let context):
    return "missing required field \"\(key.stringValue)\" at \"\(path(context.codingPath))\""
  case .typeMismatch(let type, let context):
    return "expected \(type) at \"\(path(context.codingPath))\""
  case .valueNotFound(let type, let context):
    return "expected \(type) value at \"\(path(context.codingPath))\""
  case .dataCorrupted(let context):
    if !context.debugDescription.isEmpty {
      return context.debugDescription
    }
    if let underlying = context.underlyingError {
      return String(describing: underlying)
    }
    return context.debugDescription
  @unknown default:
    return String(describing: error)
  }
}

private func path(_ codingPath: [any CodingKey]) -> String {
  codingPath.map { $0.stringValue }.joined(separator: ".")
}
