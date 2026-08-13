// Tests/CarveShellTests/CatalogTests.swift
// Why: a bad catalog can sell the wrong case, hide the free one, or
// point at a product that does not exist. Validation must fail those.

import Foundation
import Testing
import CarveCore
@testable import CarveShell

struct CatalogTests {
  @Test func shippedCatalogParsesWithFreeCase1AndPaidCase2() throws {
    let data = try Data(contentsOf: catalogURL())
    let catalog = try parseCatalog(data: data)
    #expect(catalog.entries.map(\.caseId) == ["five_minutes", "dont_wait_up"])
    let free = try #require(catalog.entry(id: "five_minutes"))
    #expect(free.access == .free)
    #expect(free.productId == nil)
    #expect(free.availability == .available)
    let paid = try #require(catalog.entry(id: "dont_wait_up"))
    #expect(paid.access == .paid)
    #expect(paid.productId == "games.carve.case.dont_wait_up")
  }

  @Test func shippedCatalogValidatesAgainstBundledCases() {
    let problems = validateCatalogBundle(
      catalogURL: catalogURL(),
      casesRoot: casesRoot())
    #expect(problems.isEmpty)
  }

  @Test func duplicateCaseIdsFail() throws {
    let catalog = try parseCatalog(data: Data(duplicateIdsJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["five_minutes", "other"]))
    #expect(problems.contains(where: { $0.contains("Duplicate catalog case id") }))
  }

  @Test func duplicateProductIdsFail() throws {
    let catalog = try parseCatalog(data: Data(duplicateProductsJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["a", "b"]))
    #expect(problems.contains(where: { $0.contains("Duplicate StoreKit product id") }))
  }

  @Test func freeEntryCannotCarryProductId() throws {
    let catalog = try parseCatalog(data: Data(freeWithProductJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["five_minutes"]))
    #expect(problems.contains(where: { $0.contains("cannot carry a productId") }))
  }

  @Test func paidEntryMustCarryProductId() throws {
    let catalog = try parseCatalog(data: Data(paidWithoutProductJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["dont_wait_up"]))
    #expect(problems.contains(where: { $0.contains("must carry a productId") }))
  }

  @Test func availableEntryMustResolveToBundledCase() throws {
    let catalog = try parseCatalog(data: Data(validSinglePaidJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["five_minutes"]))
    #expect(problems.contains(where: { $0.contains("does not resolve") }))
  }

  @Test func unknownCatalogFieldFailsClearly() {
    #expect(throws: CatalogFormatError.self) {
      try parseCatalog(data: Data(unknownFieldJSON.utf8))
    }
  }

  @Test func unknownAccessTypeFailsClearly() {
    do {
      _ = try parseCatalog(data: Data(unknownAccessJSON.utf8))
      Issue.record("expected unknown access to fail")
    } catch let error as CatalogFormatError {
      #expect(error.message.contains("access"))
    } catch {
      Issue.record("wrong error type: \(error)")
    }
  }

  @Test func comingSoonNeedNotBeBundled() throws {
    let catalog = try parseCatalog(data: Data(comingSoonJSON.utf8))
    let problems = validateCatalog(
      catalog,
      context: CatalogValidationContext(bundledCaseIds: ["five_minutes"]))
    #expect(problems.filter { $0.contains("third_case") }.isEmpty)
  }
}

private func catalogURL() -> URL {
  casesRoot().appendingPathComponent("catalog.json")
}

private func casesRoot() -> URL {
  var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  for _ in 0..<6 {
    let candidate = dir.appendingPathComponent("cases", isDirectory: true)
    if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("catalog.json").path) {
      return candidate
    }
    dir = dir.deletingLastPathComponent()
  }
  return URL(fileURLWithPath: "cases")
}

private let unknownFieldJSON = """
{
  "schemaVersion": 1,
  "priceUSD": 2.99,
  "cases": []
}
"""

private let unknownAccessJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "five_minutes",
      "title": "Five Minutes",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "subscription",
      "availability": "available"
    }
  ]
}
"""

private let duplicateIdsJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "five_minutes",
      "title": "A",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "free",
      "availability": "available"
    },
    {
      "id": "five_minutes",
      "title": "B",
      "summary": "x",
      "artwork": "b.png",
      "order": 2,
      "access": "free",
      "availability": "available"
    }
  ]
}
"""

private let duplicateProductsJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "a",
      "title": "A",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "paid",
      "productId": "games.carve.case.shared",
      "availability": "available"
    },
    {
      "id": "b",
      "title": "B",
      "summary": "x",
      "artwork": "b.png",
      "order": 2,
      "access": "paid",
      "productId": "games.carve.case.shared",
      "availability": "available"
    }
  ]
}
"""

private let freeWithProductJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "five_minutes",
      "title": "Five Minutes",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "free",
      "productId": "games.carve.case.five_minutes",
      "availability": "available"
    }
  ]
}
"""

private let paidWithoutProductJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "dont_wait_up",
      "title": "Don't Wait Up",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "paid",
      "availability": "available"
    }
  ]
}
"""

private let validSinglePaidJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "dont_wait_up",
      "title": "Don't Wait Up",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "paid",
      "productId": "games.carve.case.dont_wait_up",
      "availability": "available"
    }
  ]
}
"""

private let comingSoonJSON = """
{
  "schemaVersion": 1,
  "cases": [
    {
      "id": "five_minutes",
      "title": "Five Minutes",
      "summary": "x",
      "artwork": "a.png",
      "order": 1,
      "access": "free",
      "availability": "available"
    },
    {
      "id": "third_case",
      "title": "Later",
      "summary": "not yet",
      "artwork": "later.png",
      "order": 2,
      "access": "paid",
      "productId": "games.carve.case.third",
      "availability": "comingSoon"
    }
  ]
}
"""
