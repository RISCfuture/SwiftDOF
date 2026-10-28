import Testing
import Foundation
@testable import SwiftDOF

struct CycleTests {

  /// Currency and release dates from the FAA's published DOF schedule.
  static let publishedSchedule = [
    (currency: "20240929", release: "2024-10-01"),
    (currency: "20241124", release: "2024-11-26"),
    (currency: "20250119", release: "2025-01-21"),
    (currency: "20250316", release: "2025-03-18"),
    (currency: "20250511", release: "2025-05-13"),
    (currency: "20250706", release: "2025-07-08"),
    (currency: "20250831", release: "2025-09-02"),
    (currency: "20251026", release: "2025-10-28"),
    (currency: "20251221", release: "2025-12-23"),
    (currency: "20260215", release: "2026-02-17"),
    (currency: "20260412", release: "2026-04-14"),
    (currency: "20260607", release: "2026-06-09"),
    (currency: "20260802", release: "2026-08-04"),
    (currency: "20260927", release: "2026-09-29"),
    (currency: "20261122", release: "2026-11-24")
  ]

  private static func date(_ string: String) throws -> Date {
    try Date("\(string)T00:00:00Z", strategy: .iso8601)
  }

  private static func cycle(_ id: String) throws -> Cycle {
    try #require(Cycle(rawValue: id))
  }

  @Test
  func `reports a plausible year, month, and day for the effective cycle`() {
    let cycle = Cycle.effective
    #expect(cycle.year >= 2025)
    #expect(cycle.month >= 1 && cycle.month <= 12)
    #expect(cycle.day >= 1 && cycle.day <= 31)
  }

  @Test(arguments: publishedSchedule)
  func `matches the published schedule`(currency: String, release: String) throws {
    let cycle = try Self.cycle(currency)
    let releaseDate = try Self.date(release)
    #expect(cycle.isValid)
    #expect(cycle.releaseDate == releaseDate)
    #expect(Cycle(covering: releaseDate) == cycle)
    #expect(Cycle(covering: releaseDate.addingTimeInterval(-1)) == cycle.previous)
  }

  @Test
  func `treats a date that is not a cycle boundary as invalid`() throws {
    #expect(!(try Self.cycle("20250901")).isValid)
    #expect(!(try Self.cycle("20250915")).isValid)
  }

  @Test
  func `expires when the next cycle is released`() throws {
    let cycle = try Self.cycle("20260927")
    #expect(cycle.expirationDate == (try Self.date("2026-11-24")))
    #expect(cycle.dateRange?.end == cycle.next?.releaseDate)
  }

  @Test
  func `covers dates from its release up to but not including its expiration`() throws {
    let cycle = try Self.cycle("20260927")
    let expiration = try Self.date("2026-11-24")

    #expect(!cycle.contains(try Self.date("2026-09-28")))
    #expect(cycle.contains(try Self.date("2026-09-29")))
    #expect(cycle.contains(expiration.addingTimeInterval(-1)))
    #expect(!cycle.contains(expiration))
    #expect(try #require(cycle.next).contains(expiration))
  }

  @Test
  func `finds the cycle covering a date mid-cycle`() throws {
    let components = DateComponents(timeZone: .gmt, year: 2026, month: 10, day: 28)
    #expect(Cycle(covering: components) == (try Self.cycle("20260927")))
  }

  @Test
  func `returns the preceding cycle from previous`() throws {
    #expect(try Self.cycle("20251026").previous == (try Self.cycle("20250831")))
  }

  @Test
  func `returns the following cycle from next`() throws {
    #expect(try Self.cycle("20250831").next == (try Self.cycle("20251026")))
  }

  @Test
  func `orders an earlier cycle before a later one`() {
    let older = Cycle(year: 2025, month: 8, day: 31)
    let newer = Cycle(year: 2025, month: 10, day: 26)
    #expect(older < newer)
    #expect(!(newer < older))
    #expect(newer > older)
  }

  @Test
  func `round-trips a cycle through its raw value`() {
    let original = Cycle(year: 2025, month: 8, day: 31)
    #expect(Cycle(rawValue: original.rawValue) == original)
  }

  @Test
  func `parses a valid raw value into year, month, and day`() throws {
    let cycle = try Self.cycle("20251026")
    #expect(cycle.year == 2025)
    #expect(cycle.month == 10)
    #expect(cycle.day == 26)
  }

  @Test
  func `returns nil for a malformed raw value`() {
    #expect(Cycle(rawValue: "invalid") == nil)
    #expect(Cycle(rawValue: "2025") == nil)
    #expect(Cycle(rawValue: "202509011") == nil)
  }

  @Test
  func `formats the ID as a zero-padded year, month, and day`() {
    #expect(Cycle(year: 2025, month: 8, day: 31).id == "20250831")
    #expect(Cycle(year: 2026, month: 2, day: 5).id == "20260205")
  }

  @Test
  func `describes a cycle by its ID`() {
    let cycle = Cycle(year: 2025, month: 8, day: 31)
    #expect(cycle.description == cycle.id)
  }

  @Test
  func `reports the current cycle as effective`() {
    #expect(Cycle.effective.isEffective)
  }

  @Test
  func `returns the currency date in GMT`() throws {
    let cycle = Cycle(year: 2026, month: 9, day: 27)
    #expect(cycle.currencyDate == (try Self.date("2026-09-27")))
  }
}
