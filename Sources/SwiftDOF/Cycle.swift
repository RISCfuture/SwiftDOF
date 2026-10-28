public import Foundation

/**
 Represents a DOF publication cycle.

 The FAA publishes the Digital Obstacle File every 56 days. Each file reflects obstacle changes
 through its *currency date*, a Sunday that the file's header declares and its filename carries.
 The FAA releases the file two days later, on the Tuesday, and it stays current until the next
 cycle's release. A cycle is identified by its currency date.
 */
public struct Cycle: Sendable, Codable, Equatable, Hashable {
  /// The currency date of the datum cycle (August 31, 2025).
  private static let datum = (year: 2025, month: 8, day: 31)

  /// The period between DOF updates in days.
  private static let period = 56

  /// The days between a cycle's currency date and its release.
  private static let releaseDelay = 2

  /// The calendar used for date calculations.
  private static var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    return cal
  }

  /// The datum's currency date as a Foundation Date.
  private static var datumDate: Date {
    let components = DateComponents(
      timeZone: .gmt,
      year: datum.year,
      month: datum.month,
      day: datum.day
    )
    guard let date = calendar.date(from: components) else {
      preconditionFailure("The DOF datum is not a valid Gregorian date")
    }
    return date
  }

  /// The most recently released cycle as of now.
  public static var effective: Self { Self(covering: .now) }

  /// The year of this cycle's currency date.
  public let year: UInt

  /// The month of this cycle's currency date.
  public let month: UInt8

  /// The day of this cycle's currency date.
  public let day: UInt8

  /// The cycle preceding this one (56 days earlier).
  public var previous: Self? { cycle(offsetByDays: -Self.period) }

  /// The cycle following this one (56 days later).
  public var next: Self? { cycle(offsetByDays: Self.period) }

  /// Whether this cycle falls on a valid cycle boundary.
  ///
  /// A cycle is valid if its currency date falls exactly on a 56-day boundary from the datum.
  public var isValid: Bool {
    guard let currencyDate, let daysFromDatum = Self.days(from: Self.datumDate, to: currencyDate)
    else {
      return false
    }
    return daysFromDatum.isMultiple(of: Self.period)
  }

  /// Whether this is the most recently released cycle.
  public var isEffective: Bool { self == Self.effective }

  /// The date components of this cycle's currency date.
  public var currencyDateComponents: DateComponents {
    .init(timeZone: .gmt, year: Int(year), month: Int(month), day: Int(day))
  }

  /**
   The currency date of this cycle (midnight UTC).

   The data reflects obstacle changes through this date. The FAA declares it in the file's
   `CURRENCY DATE` header and names the distribution file for it (`DOF_YYMMDD.zip`).
   */
  public var currencyDate: Date? {
    Self.calendar.date(from: currencyDateComponents)
  }

  /// The date the FAA releases this cycle (midnight UTC), two days after its currency date.
  public var releaseDate: Date? {
    guard let currencyDate else { return nil }
    return Self.calendar.date(byAdding: .day, value: Self.releaseDelay, to: currencyDate)
  }

  /// The moment this cycle is superseded, which is the next cycle's ``releaseDate``.
  public var expirationDate: Date? { next?.releaseDate }

  /// The period when this cycle is current.
  ///
  /// The interval runs from ``releaseDate`` to ``expirationDate``. Its end belongs to the next
  /// cycle; use ``contains(_:)`` to test a date against it.
  public var dateRange: DateInterval? {
    guard let releaseDate, let expirationDate else { return nil }
    return DateInterval(start: releaseDate, end: expirationDate)
  }

  /// Creates a cycle with the specified currency date.
  ///
  /// - Parameters:
  ///   - year: The year of the currency date.
  ///   - month: The month of the currency date.
  ///   - day: The day of the currency date.
  init(year: UInt, month: UInt8, day: UInt8) {
    self.year = year
    self.month = month
    self.day = day
  }

  /// Creates the cycle current on the specified date.
  ///
  /// The returned cycle is the most recent cycle released on or before the given date.
  ///
  /// - Parameter date: The date to find a covering cycle for.
  public init(covering date: Date) {
    // DateComponents from a valid Date will always produce a valid cycle
    self = Self(covering: Self.calendar.dateComponents([.year, .month, .day], from: date))!
  }

  /// Creates the cycle current on the date represented by the given components.
  ///
  /// The returned cycle is the most recent cycle released on or before the given date.
  /// Returns nil if the components don't represent a valid date.
  ///
  /// - Parameter components: The date components to find a covering cycle for.
  public init?(covering components: DateComponents) {
    guard let date = Self.calendar.date(from: components),
      let daysFromDatum = Self.days(from: Self.datumDate, to: date)
    else {
      return nil
    }

    // Floor division: Swift's / truncates toward zero, not negative infinity
    let (quotient, remainder) = (daysFromDatum - Self.releaseDelay)
      .quotientAndRemainder(dividingBy: Self.period)
    let cycleNumber = remainder < 0 ? quotient - 1 : quotient

    guard
      let currencyDate = Self.calendar.date(
        byAdding: .day,
        value: cycleNumber * Self.period,
        to: Self.datumDate
      )
    else {
      return nil
    }

    self.init(
      dateComponents: Self.calendar.dateComponents([.year, .month, .day], from: currencyDate)
    )
  }

  /// Creates a cycle from date components that already fall on a cycle boundary.
  ///
  /// - Parameter components: Components carrying a year, month, and day.
  private init?(dateComponents components: DateComponents) {
    guard let year = components.year,
      let month = components.month,
      let day = components.day
    else {
      return nil
    }
    self.init(year: UInt(year), month: UInt8(month), day: UInt8(day))
  }

  /// The whole days from one date to another, negative when `end` precedes `start`.
  private static func days(from start: Date, to end: Date) -> Int? {
    calendar.dateComponents([.day], from: start, to: end).day
  }

  /// The cycle whose currency date is `days` away from this one's.
  private func cycle(offsetByDays days: Int) -> Self? {
    guard let currencyDate,
      let shiftedDate = Self.calendar.date(byAdding: .day, value: days, to: currencyDate)
    else {
      return nil
    }
    return Self(
      dateComponents: Self.calendar.dateComponents([.year, .month, .day], from: shiftedDate)
    )
  }
}

extension Cycle: LosslessStringConvertible {
  public var description: String { id }

  /// Creates a cycle from a YYYYMMDD string.
  ///
  /// - Parameter description: A string in YYYYMMDD format.
  public init?(_ description: String) {
    self.init(rawValue: description)
  }
}

extension Cycle: Comparable {
  public static func < (lhs: Cycle, rhs: Cycle) -> Bool {
    if lhs.year != rhs.year { return lhs.year < rhs.year }
    if lhs.month != rhs.month { return lhs.month < rhs.month }
    return lhs.day < rhs.day
  }
}

extension Cycle: Identifiable {
  /// The unique identifier for this cycle: its currency date in YYYYMMDD format.
  public var id: String {
    unsafe String(format: "%04d%02d%02d", year, month, day)
  }
}

extension Cycle: RawRepresentable {
  public typealias RawValue = String

  public var rawValue: String { id }

  /// Creates a cycle from a YYYYMMDD currency date string.
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

// MARK: - Factory Methods

extension Cycle {
  /// Returns the cycle current on the given date.
  ///
  /// - Parameter date: The date to find the cycle for.
  /// - Returns: The most recent cycle released on or before the date.
  public static func cycle(for date: Date) -> Self {
    Self(covering: date)
  }

  /// Returns whether this cycle is current on the given date.
  ///
  /// A cycle is current from its ``releaseDate`` up to, but not including, its
  /// ``expirationDate``.
  ///
  /// - Parameter date: The date to check.
  /// - Returns: `true` if the date falls within this cycle's current period.
  public func contains(_ date: Date) -> Bool {
    guard let releaseDate, let expirationDate else { return false }
    return (releaseDate..<expirationDate).contains(date)
  }
}
