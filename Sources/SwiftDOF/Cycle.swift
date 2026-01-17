import Foundation

/// Represents a DOF publication cycle.
///
/// The FAA updates the Digital Obstacle File every 56 days, starting from September 1, 2025.
/// Each cycle represents the effective date of a DOF publication.
public struct Cycle: Sendable, Codable, Equatable, Hashable {
  /// The datum date for cycle calculations (September 1, 2025).
  private static let datum = (year: 2025, month: 9, day: 1)

  /// The period between DOF updates in days.
  private static let period = 56

  /// The calendar used for date calculations.
  private static var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    return cal
  }

  /// The datum date as a Foundation Date.
  private static var datumDate: Date {
    let components = DateComponents(
      timeZone: .gmt,
      year: datum.year,
      month: datum.month,
      day: datum.day
    )
    return calendar.date(from: components)!
  }

  /// The current active cycle based on today's date.
  public static var current: Self { Self(covering: .now) }

  /// The year of this cycle.
  public let year: UInt

  /// The month of this cycle.
  public let month: UInt8

  /// The day of this cycle.
  public let day: UInt8

  /// The cycle preceding this one (56 days earlier).
  public var previous: Self? {
    guard let firstDate,
      let previousDate = Self.calendar.date(byAdding: .day, value: -Self.period, to: firstDate)
    else {
      return nil
    }
    let components = Self.calendar.dateComponents([.year, .month, .day], from: previousDate)
    return Self(
      year: UInt(components.year!),
      month: UInt8(components.month!),
      day: UInt8(components.day!)
    )
  }

  /// The cycle following this one (56 days later).
  public var next: Self? {
    guard let firstDate,
      let nextDate = Self.calendar.date(byAdding: .day, value: Self.period, to: firstDate)
    else {
      return nil
    }
    let components = Self.calendar.dateComponents([.year, .month, .day], from: nextDate)
    return Self(
      year: UInt(components.year!),
      month: UInt8(components.month!),
      day: UInt8(components.day!)
    )
  }

  /// Whether this cycle falls on a valid cycle boundary.
  ///
  /// A cycle is valid if it falls exactly on a 56-day boundary from the datum date.
  public var isValid: Bool {
    guard let firstDate else { return false }

    guard
      let daysFromDatum = Self.calendar.dateComponents(
        [.day],
        from: Self.datumDate,
        to: firstDate
      ).day
    else {
      return false
    }

    return daysFromDatum.isMultiple(of: Self.period)
  }

  /// Whether this is the currently active cycle.
  public var isCurrent: Bool { self == Self.current }

  /// The start date components for this cycle.
  public var firstDateComponents: DateComponents {
    .init(timeZone: .gmt, year: Int(year), month: Int(month), day: Int(day))
  }

  /// The Foundation Date representation of the start of this cycle.
  public var firstDate: Date? {
    Self.calendar.date(from: firstDateComponents)
  }

  /// The date components for the last day of data coverage (one day before cycle start).
  ///
  /// The FAA DOF filename uses this date, not the cycle start date.
  public var lastDateComponents: DateComponents? {
    guard let firstDate,
      let lastDate = Self.calendar.date(byAdding: .day, value: -1, to: firstDate)
    else {
      return nil
    }
    return Self.calendar.dateComponents([.year, .month, .day], from: lastDate)
  }

  /// The last day of data coverage (one day before cycle start).
  ///
  /// The FAA DOF filename uses this date, not the cycle start date.
  public var lastDate: Date? {
    guard let lastDateComponents else { return nil }
    return Self.calendar.date(from: lastDateComponents)
  }

  /// Creates a cycle with the specified year, month, and day.
  ///
  /// - Parameters:
  ///   - year: The year of the cycle.
  ///   - month: The month of the cycle.
  ///   - day: The day of the cycle.
  init(year: UInt, month: UInt8, day: UInt8) {
    self.year = year
    self.month = month
    self.day = day
  }

  /// Creates a cycle covering the specified date.
  ///
  /// The returned cycle is the most recent cycle that started on or before the given date.
  ///
  /// - Parameter date: The date to find a covering cycle for.
  public init(covering date: Date) {
    // DateComponents from a valid Date will always produce a valid cycle
    self = Self(covering: Self.calendar.dateComponents([.year, .month, .day], from: date))!
  }

  /// Creates a cycle covering the date represented by the given components.
  ///
  /// The returned cycle is the most recent cycle that started on or before the given date.
  /// Returns nil if the components don't represent a valid date.
  ///
  /// - Parameter components: The date components to find a covering cycle for.
  public init?(covering components: DateComponents) {
    guard let date = Self.calendar.date(from: components) else {
      return nil
    }

    // Calculate days from datum (can be negative for dates before datum)
    guard
      let daysFromDatum = Self.calendar.dateComponents(
        [.day],
        from: Self.datumDate,
        to: date
      ).day
    else {
      return nil
    }

    // Floor division to find cycle number (Swift's / truncates toward zero, not negative infinity)
    let cycleNumber: Int
    if daysFromDatum >= 0 {
      cycleNumber = daysFromDatum / Self.period
    } else {
      let (q, r) = daysFromDatum.quotientAndRemainder(dividingBy: Self.period)
      cycleNumber = r == 0 ? q : q - 1
    }

    let daysToAdd = cycleNumber * Self.period

    guard let cycleDate = Self.calendar.date(byAdding: .day, value: daysToAdd, to: Self.datumDate)
    else {
      return nil
    }

    let resultComponents = Self.calendar.dateComponents([.year, .month, .day], from: cycleDate)

    guard let year = resultComponents.year,
      let month = resultComponents.month,
      let day = resultComponents.day
    else {
      return nil
    }

    self.init(year: UInt(year), month: UInt8(month), day: UInt8(day))
  }
}

extension Cycle: CustomStringConvertible {
  public var description: String { id }
}

extension Cycle: Comparable {
  public static func < (lhs: Cycle, rhs: Cycle) -> Bool {
    if lhs.year != rhs.year { return lhs.year < rhs.year }
    if lhs.month != rhs.month { return lhs.month < rhs.month }
    return lhs.day < rhs.day
  }
}

extension Cycle: Identifiable {
  /// The unique identifier for this cycle in YYYYMMDD format.
  public var id: String {
    String(format: "%04d%02d%02d", year, month, day)
  }
}

extension Cycle: RawRepresentable {
  public typealias RawValue = String

  public var rawValue: String { id }

  /// Creates a cycle from a YYYYMMDD string.
  ///
  /// - Parameter rawValue: A string in YYYYMMDD format.
  public init?(rawValue: String) {
    guard rawValue.count == 8 else { return nil }

    let yearStr = rawValue.prefix(4)
    let monthStr = rawValue.dropFirst(4).prefix(2)
    let dayStr = rawValue.suffix(2)

    guard let year = UInt(yearStr),
      let month = UInt8(monthStr),
      let day = UInt8(dayStr),
      month >= 1, month <= 12,
      day >= 1, day <= 31
    else {
      return nil
    }

    self.init(year: year, month: month, day: day)
  }
}
