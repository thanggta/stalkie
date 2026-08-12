public struct QuestionResult: Equatable, Sendable {
  public let questionId: String
  public let given: String
  public let correct: String
  public let isCorrect: Bool

  public init(questionId: String, given: String, correct: String, isCorrect: Bool) {
    self.questionId = questionId
    self.given = given
    self.correct = correct
    self.isCorrect = isCorrect
  }
}

public struct VerdictReport: Equatable, Sendable {
  public let results: [QuestionResult]

  public init(results: [QuestionResult]) {
    self.results = results
  }

  public var total: Int { results.count }
  public var correct: Int { results.filter(\.isCorrect).count }
  public var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

public enum FileVerdictResult: Equatable, Sendable {
  /// Player tried to close without answering every question. No score is issued.
  case incomplete(missingQuestionIds: [String])
  case filed(VerdictReport)
}

/// Scores on accuracy. An unanswered question is wrong if this is called
/// directly — prefer `fileVerdict`, which refuses to score incomplete filings.
public func scoreVerdict(_ caseFile: CaseFile, _ answers: [String: String]) -> VerdictReport {
  let results = caseFile.questions.map { q in
    let given = answers[q.id] ?? ""
    return QuestionResult(
      questionId: q.id,
      given: given,
      correct: q.correct,
      isCorrect: given == q.correct)
  }
  return VerdictReport(results: results)
}

/// Forces a complete answer set before scoring. Empty strings count as missing.
public func fileVerdict(_ caseFile: CaseFile, _ answers: [String: String]) -> FileVerdictResult {
  let missing = caseFile.questions.compactMap { q -> String? in
    guard let given = answers[q.id], !given.isEmpty else { return q.id }
    return nil
  }
  if !missing.isEmpty {
    return .incomplete(missingQuestionIds: missing)
  }
  return .filed(scoreVerdict(caseFile, answers))
}
