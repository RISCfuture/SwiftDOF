import Testing
import Foundation
@testable import SwiftDOF

struct CycleTests {

  @Test("Effective cycle is valid")
  func testEffectiveCycleIsValid() {
    let cycle = Cycle.effective
    #expect(cycle.year >= 2025)
    #expect(cycle.month >= 1 && cycle.month <= 12)
    #expect(cycle.day >= 1 && cycle.day <= 31)
  }

  @Test("Datum cycle (Sep 1, 2025) is valid")
  func testDatumCycleIsValid() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.isValid)
    #expect(cycle.id == "20250901")
  }

  @Test("Second cycle (Oct 27, 2025) is valid")
  func testSecondCycleIsValid() {
    let cycle = Cycle(year: 2025, month: 10, day: 27)
    #expect(cycle.isValid)
    #expect(cycle.id == "20251027")
  }

  @Test("Third cycle (Dec 22, 2025) is valid")
  func testThirdCycleIsValid() {
    let cycle = Cycle(year: 2025, month: 12, day: 22)
    #expect(cycle.isValid)
    #expect(cycle.id == "20251222")
  }

  @Test("Non-boundary date is invalid")
  func testNonBoundaryDateIsInvalid() {
    // Sep 15 is not a cycle boundary
    let cycle = Cycle(year: 2025, month: 9, day: 15)
    #expect(!cycle.isValid)
  }

  @Test("Previous cycle calculation")
  func testPreviousCycle() throws {
    let cycle = Cycle(year: 2025, month: 10, day: 27)
    let previous = try #require(cycle.previous)
    #expect(previous.year == 2025)
    #expect(previous.month == 9)
    #expect(previous.day == 1)
  }

  @Test("Next cycle calculation")
  func testNextCycle() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    let next = try #require(cycle.next)
    #expect(next.year == 2025)
    #expect(next.month == 10)
    #expect(next.day == 27)
  }

  @Test("Cycle comparison - less than")
  func testCycleComparisonLessThan() {
    let older = Cycle(year: 2025, month: 9, day: 1)
    let newer = Cycle(year: 2025, month: 10, day: 27)
    #expect(older < newer)
    #expect(!(newer < older))
  }

  @Test("Cycle comparison - greater than")
  func testCycleComparisonGreaterThan() {
    let older = Cycle(year: 2025, month: 9, day: 1)
    let newer = Cycle(year: 2025, month: 10, day: 27)
    #expect(newer > older)
  }

  @Test("Cycle equality")
  func testCycleEquality() {
    let cycle1 = Cycle(year: 2025, month: 9, day: 1)
    let cycle2 = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle1 == cycle2)
  }

  @Test("RawRepresentable round-trip")
  func testRawRepresentableRoundTrip() {
    let original = Cycle(year: 2025, month: 9, day: 1)
    let rawValue = original.rawValue
    let restored = Cycle(rawValue: rawValue)
    #expect(restored == original)
  }

  @Test("RawRepresentable initialization with valid string")
  func testRawRepresentableValidString() throws {
    let cycle = try #require(Cycle(rawValue: "20251027"))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 10)
    #expect(cycle.day == 27)
  }

  @Test("RawRepresentable initialization with invalid string")
  func testRawRepresentableInvalidString() {
    #expect(Cycle(rawValue: "invalid") == nil)
    #expect(Cycle(rawValue: "2025") == nil)
    #expect(Cycle(rawValue: "202509011") == nil)
  }

  @Test("Cycle covering arbitrary date")
  func testCycleCoveringArbitraryDate() throws {
    // Sep 15, 2025 should be covered by Sep 1, 2025 cycle
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 9, day: 15)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 9)
    #expect(cycle.day == 1)
  }

  @Test("Cycle covering date in second cycle")
  func testCycleCoveringDateInSecondCycle() throws {
    // Nov 1, 2025 should be covered by Oct 27, 2025 cycle
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 11, day: 1)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 10)
    #expect(cycle.day == 27)
  }

  @Test("Cycle covering date before datum")
  func testCycleCoveringDateBeforeDatum() throws {
    // Aug 15, 2025 is before datum (Sep 1), should be covered by Jul 7, 2025 (56 days before datum)
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 8, day: 15)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 7)
    #expect(cycle.day == 7)
  }

  @Test("Cycle covering date exactly on pre-datum boundary")
  func testCycleCoveringDateExactlyOnPreDatumBoundary() throws {
    // Jul 7, 2025 is exactly 56 days before datum
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 7, day: 7)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 7)
    #expect(cycle.day == 7)
    #expect(cycle.isValid)
  }

  @Test("Cycle ID format")
  func testCycleIdFormat() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.id == "20250901")

    let cycle2 = Cycle(year: 2026, month: 12, day: 15)
    #expect(cycle2.id == "20261215")
  }

  @Test("Cycle description equals ID")
  func testCycleDescriptionEqualsId() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.description == cycle.id)
  }

  @Test("isEffective returns true for effective cycle")
  func testIsEffective() {
    let effective = Cycle.effective
    #expect(effective.isEffective)

    // A past cycle should not be effective
    let past = Cycle(year: 2025, month: 9, day: 1)
    // This may or may not be effective depending on when test runs
    // so we just verify it doesn't crash
    _ = past.isEffective
  }

  @Test("Cycle date property returns valid date")
  func testCycleDateProperty() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    let date = try #require(cycle.firstDate)

    // Use GMT calendar to match how Cycle stores dates
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    #expect(components.year == 2025)
    #expect(components.month == 9)
    #expect(components.day == 1)
  }

  @Test("dateRange covers full cycle")
  func testDateRange() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    let dateRange = try #require(cycle.dateRange)

    // Duration should be 56 days
    let expectedDuration: TimeInterval = 56 * 24 * 60 * 60
    #expect(dateRange.duration == expectedDuration)

    // Start should be effectiveDate
    #expect(dateRange.start == cycle.effectiveDate)

    // End should be expirationDate
    #expect(dateRange.end == cycle.expirationDate)
  }

  @Test("contains returns true for date within cycle")
  func testContainsDateWithinCycle() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)

    // Create a date in the middle of the cycle (Sep 15, 2025)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let midCycleDate = try #require(
      calendar.date(from: DateComponents(timeZone: .gmt, year: 2025, month: 9, day: 15))
    )

    #expect(cycle.contains(midCycleDate))
  }

  @Test("contains returns false for date outside cycle")
  func testContainsDateOutsideCycle() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)

    // Create a date before the cycle (Aug 15, 2025)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let beforeDate = try #require(
      calendar.date(from: DateComponents(timeZone: .gmt, year: 2025, month: 8, day: 15))
    )

    #expect(!cycle.contains(beforeDate))

    // Create a date after the cycle (Nov 1, 2025)
    let afterDate = try #require(
      calendar.date(from: DateComponents(timeZone: .gmt, year: 2025, month: 11, day: 1))
    )

    #expect(!cycle.contains(afterDate))
  }

  @Test("cycle(for:) returns correct cycle")
  func testCycleForDate() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt

    // Sep 15, 2025 should be covered by Sep 1, 2025 cycle
    let date = try #require(
      calendar.date(from: DateComponents(timeZone: .gmt, year: 2025, month: 9, day: 15))
    )

    let cycle = Cycle.cycle(for: date)
    #expect(cycle.year == 2025)
    #expect(cycle.month == 9)
    #expect(cycle.day == 1)
  }

  @Test("expirationDate returns exact expiration moment")
  func testExpirationDateExactMoment() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    let effectiveDate = try #require(cycle.effectiveDate)
    let expirationDate = try #require(cycle.expirationDate)

    // expirationDate should be exactly 56 days after effectiveDate
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let daysDifference = calendar.dateComponents([.day], from: effectiveDate, to: expirationDate)
      .day
    #expect(daysDifference == 56)

    // expirationDate should equal the next cycle's effectiveDate
    let nextCycle = try #require(cycle.next)
    #expect(expirationDate == nextCycle.effectiveDate)
  }
}
