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

/// Scores on accuracy, not completeness. An unanswered question is wrong —
/// filing an incomplete report is a choice with a cost.
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
