// Sources/CarveCLILib/CLIRunner.swift
import CarveCore
import Foundation

/// The whole `validate_case` flow as a library, so every branch is testable
/// without spawning a process. See tool/validate_case.dart.
public enum CLIRunner {
  /// Runs the whole validate_case flow. Returns the process exit code (0 valid, 1 invalid).
  /// Never throws; every failure is reported to stderr. Output goes straight to
  /// FileHandle.standardOutput/standardError.
  public static func run(arguments: [String], fileManager: FileManager = .default) -> Int32 {
    run(
      arguments: arguments,
      fileManager: fileManager,
      stdout: { write($0, to: .standardOutput) },
      stderr: { write($0, to: .standardError) })
  }

  /// The testable core: output destinations are injectable so tests can assert
  /// on the text without touching the real stdio handles.
  public static func run(
    arguments: [String],
    fileManager: FileManager = .default,
    stdout: (String) -> Void,
    stderr: (String) -> Void
  ) -> Int32 {
    guard let dir = arguments.first else {
      stderr("usage: CarveCLI <case-directory>")
      return 1
    }

    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: dir, isDirectory: &isDirectory)
    guard exists, isDirectory.boolValue else {
      stderr("No such case directory: \(dir)")
      return 1
    }

    let manifestPath = "\(dir)/case.json"
    guard fileManager.fileExists(atPath: manifestPath) else {
      stderr("Missing case.json in \(dir)")
      return 1
    }

    do {
      guard let manifestData = fileManager.contents(atPath: manifestPath) else {
        throw CaseFormatError("Could not read \(manifestPath).")
      }

      var fragmentFiles: [(name: String, data: Data)] = []
      let fragmentsDir = "\(dir)/fragments"
      if fileManager.fileExists(atPath: fragmentsDir, isDirectory: &isDirectory),
        isDirectory.boolValue
      {
        let names = try fileManager.contentsOfDirectory(atPath: fragmentsDir).sorted()
        for name in names where name.hasSuffix(".json") {
          guard let data = fileManager.contents(atPath: "\(fragmentsDir)/\(name)") else {
            throw CaseFormatError("Could not read \(fragmentsDir)/\(name).")
          }
          fragmentFiles.append((name: name, data: data))
        }
      }

      let caseFile = try parseCase(manifestData: manifestData, fragmentFiles: fragmentFiles)
      let problems = validateCase(caseFile)

      if problems.isEmpty {
        stdout("OK  \(caseFile.id) — \"\(caseFile.title)\"")
        let questionCount = caseFile.questions.count
        let gated = caseFile.fragments.values.filter { $0.hiddenUntil != nil }.count
        stdout(
          "    \(caseFile.fragments.count) fragments (\(gated) gated), "
            + "\(caseFile.sectorMap.count) on sector map, "
            + "\(questionCount) question\(questionCount == 1 ? "" : "s")")
        return 0
      }

      stderr("FAILED  \(dir) — \(problems.count) problem(s):")
      for problem in problems {
        stderr("  • \(problem)")
      }
      return 1
    } catch let error as CaseFormatError {
      stderr("FAILED  \(dir)")
      stderr("  • \(error.message)")
      return 1
    } catch {
      stderr("FAILED  \(dir)")
      stderr("  • \(error)")
      return 1
    }
  }

  // FileHandle.write is unbuffered, so nothing is lost to stdio buffering
  // before exit() — unlike print, which can be dropped.
  private static func write(_ line: String, to handle: FileHandle) {
    guard let data = (line + "\n").data(using: .utf8) else { return }
    handle.write(data)
  }
}
