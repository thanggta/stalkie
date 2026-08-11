import Testing
@testable import CarveCore

struct VerdictTests {
  private func fixture() -> CaseFile {
    CaseFile(
      schemaVersion: 1,
      id: "t",
      title: "T",
      cycleBudget: 10,
      sectorMap: [],
      questions: [
        VerdictQuestion(
          id: "q1", prompt: "Who?", options: ["a", "b"], correct: "a", supportedBy: ["f1"]),
        VerdictQuestion(
          id: "q2", prompt: "When?", options: ["x", "y"], correct: "y", supportedBy: ["f2"]),
      ],
      fragments: [:]
    )
  }

  @Test func scoresOnAccuracyOverAnsweredQuestions() {
    let report = scoreVerdict(fixture(), ["q1": "a", "q2": "x"])
    #expect(report.correct == 1)
    #expect(report.total == 2)
    #expect(report.accuracy == 0.5)
  }

  @Test func unansweredQuestionCountsAsWrongNotSkipped() {
    // Filing an incomplete report is a choice with a cost. Silently
    // excluding blanks would let a player score 100% by answering one question.
    let report = scoreVerdict(fixture(), ["q1": "a"])
    #expect(report.correct == 1)
    #expect(report.total == 2)
    #expect(report.results.first { $0.questionId == "q2" }?.isCorrect == false)
  }

  @Test func ignoresAnswersToQuestionsCaseDoesNotAsk() {
    let report = scoreVerdict(fixture(), ["q1": "a", "q2": "y", "q99": "z"])
    #expect(report.total == 2)
    #expect(report.correct == 2)
  }

  @Test func perfectReportScoresOnePointZero() {
    let report = scoreVerdict(fixture(), ["q1": "a", "q2": "y"])
    #expect(report.accuracy == 1.0)
  }
}
