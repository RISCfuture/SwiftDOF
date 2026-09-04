import Testing
import Foundation
@testable import SwiftDOF

struct CycleTests {

  @Test
  func `reports a plausible year, month, and day for the effective cycle`() {
    let cycle = Cycle.effective
    #expect(cycle.year >= 2025)
    #expect(cycle.month >= 1 && cycle.month <= 12)
    #expect(cycle.day >= 1 && cycle.day <= 31)
  }

  @Test
  func `treats the datum cycle of Sep 1, 2025 as valid`() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.isValid)
    #expect(cycle.id == "20250901")
  }

  @Test
  func `treats the second cycle of Oct 27, 2025 as valid`() {
    let cycle = Cycle(year: 2025, month: 10, day: 27)
    #expect(cycle.isValid)
    #expect(cycle.id == "20251027")
  }

  @Test
  func `treats the third cycle of Dec 22, 2025 as valid`() {
    let cycle = Cycle(year: 2025, month: 12, day: 22)
    #expect(cycle.isValid)
    #expect(cycle.id == "20251222")
  }

  @Test
  func `treats a date that is not a cycle boundary as invalid`() {
    // Sep 15 is not a cycle boundary
    let cycle = Cycle(year: 2025, month: 9, day: 15)
    #expect(!cycle.isValid)
  }

  @Test
  func `returns the preceding cycle from previous`() throws {
    let cycle = Cycle(year: 2025, month: 10, day: 27)
    let previous = try #require(cycle.previous)
    #expect(previous.year == 2025)
    #expect(previous.month == 9)
    #expect(previous.day == 1)
  }

  @Test
  func `returns the following cycle from next`() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    let next = try #require(cycle.next)
    #expect(next.year == 2025)
    #expect(next.month == 10)
    #expect(next.day == 27)
  }

  @Test
  func `orders an earlier cycle before a later one`() {
    let older = Cycle(year: 2025, month: 9, day: 1)
    let newer = Cycle(year: 2025, month: 10, day: 27)
    #expect(older < newer)
    #expect(!(newer < older))
  }

  @Test
  func `orders a later cycle after an earlier one`() {
    let older = Cycle(year: 2025, month: 9, day: 1)
    let newer = Cycle(year: 2025, month: 10, day: 27)
    #expect(newer > older)
  }

  @Test
  func `considers two cycles with the same date equal`() {
    let cycle1 = Cycle(year: 2025, month: 9, day: 1)
    let cycle2 = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle1 == cycle2)
  }

  @Test
  func `round-trips a cycle through its raw value`() {
    let original = Cycle(year: 2025, month: 9, day: 1)
    let rawValue = original.rawValue
    let restored = Cycle(rawValue: rawValue)
    #expect(restored == original)
  }

  @Test
  func `parses a valid raw value into year, month, and day`() throws {
    let cycle = try #require(Cycle(rawValue: "20251027"))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 10)
    #expect(cycle.day == 27)
  }

  @Test
  func `returns nil for a malformed raw value`() {
    #expect(Cycle(rawValue: "invalid") == nil)
    #expect(Cycle(rawValue: "2025") == nil)
    #expect(Cycle(rawValue: "202509011") == nil)
  }

  @Test
  func `finds the cycle covering a date mid-cycle`() throws {
    // Sep 15, 2025 should be covered by Sep 1, 2025 cycle
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 9, day: 15)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 9)
    #expect(cycle.day == 1)
  }

  @Test
  func `finds the cycle covering a date in the second cycle`() throws {
    // Nov 1, 2025 should be covered by Oct 27, 2025 cycle
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 11, day: 1)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 10)
    #expect(cycle.day == 27)
  }

  @Test
  func `finds the cycle covering a date before the datum`() throws {
    // Aug 15, 2025 is before datum (Sep 1), should be covered by Jul 7, 2025 (56 days before datum)
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 8, day: 15)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 7)
    #expect(cycle.day == 7)
  }

  @Test
  func `finds a valid cycle for a date exactly on a pre-datum boundary`() throws {
    // Jul 7, 2025 is exactly 56 days before datum
    let components = DateComponents(timeZone: .gmt, year: 2025, month: 7, day: 7)
    let cycle = try #require(Cycle(covering: components))
    #expect(cycle.year == 2025)
    #expect(cycle.month == 7)
    #expect(cycle.day == 7)
    #expect(cycle.isValid)
  }

  @Test
  func `formats the ID as a zero-padded year, month, and day`() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.id == "20250901")

    let cycle2 = Cycle(year: 2026, month: 12, day: 15)
    #expect(cycle2.id == "20261215")
  }

  @Test
  func `describes a cycle by its ID`() {
    let cycle = Cycle(year: 2025, month: 9, day: 1)
    #expect(cycle.description == cycle.id)
  }

  @Test
  func `reports the current cycle as effective`() {
    let effective = Cycle.effective
    #expect(effective.isEffective)

    // A past cycle should not be effective
    let past = Cycle(year: 2025, month: 9, day: 1)
    // This may or may not be effective depending on when test runs
    // so we just verify it doesn't crash
    _ = past.isEffective
  }

  @Test
  func `returns the first date of the cycle in GMT`() throws {
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

  @Test
  func `spans 56 days from the effective date to the expiration date`() throws {
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

  @Test
  func `contains a date inside the cycle`() throws {
    let cycle = Cycle(year: 2025, month: 9, day: 1)

    // Create a date in the middle of the cycle (Sep 15, 2025)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    let midCycleDate = try #require(
      calendar.date(from: DateComponents(timeZone: .gmt, year: 2025, month: 9, day: 15))
    )

    #expect(cycle.contains(midCycleDate))
  }

  @Test
  func `excludes dates before and after the cycle`() throws {
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

  @Test
  func `returns the cycle covering a given date`() throws {
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

  @Test
  func `expires 56 days after the effective date, when the next cycle begins`() throws {
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
