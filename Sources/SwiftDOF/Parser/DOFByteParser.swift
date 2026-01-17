import Foundation

/// Parser for FAA Digital Obstacle File (DOF) fixed-width format.
/// Works directly on byte slices for maximum performance.
struct DOFByteParser: Sendable {

  // MARK: Field Positions (0-indexed, end exclusive)

  private static let fields = (
    oasNumber: 0..<9,
    verification: 10..<11,
    country: 12..<14,
    state: 15..<17,
    city: 18..<35,
    latDegrees: 35..<37,
    latMinutes: 38..<40,
    latSeconds: 41..<47,  // includes direction (N/S)
    lonDegrees: 48..<51,
    lonMinutes: 52..<54,
    lonSeconds: 55..<61,  // includes direction (E/W)
    obstacleType: 62..<81,
    quantity: 81..<82,
    aglHeight: 83..<88,
    mslHeight: 89..<94,
    lighting: 95..<96,
    accuracyH: 97..<98,
    marking: 99..<100,
    faaIndicator: 101..<102,
    studyNumber: 103..<117,
    action: 118..<119,
    lastUpdated: 120..<127
  )

  /// Minimum line length required for parsing.
  static let minimumLineLength = 127

  /// Pattern to match in currency date header.
  private static let currencyDatePattern: [UInt8] = Array("CURRENCY DATE = ".utf8)

  // MARK: Public API

  /// Parse a single DOF record line from raw bytes.
  static func parseLine<T: RandomAccessCollection>(
    _ bytes: T,
    lineNumber: Int = 0
  ) throws -> Obstacle where T.Element == UInt8, T.Index == Int {
    guard bytes.count >= minimumLineLength else {
      throw DOFError.lineTooShort(
        expected: minimumLineLength,
        actual: bytes.count,
        line: lineNumber
      )
    }

    let base = bytes.startIndex

    // String fields
    let oasNumber = try slice(bytes, base, fields.oasNumber).toString()
    let country = try slice(bytes, base, fields.country).toString()
    let stateSlice = slice(bytes, base, fields.state)
    let city = try slice(bytes, base, fields.city).toString()
    let studyNumber = try slice(bytes, base, fields.studyNumber).toString()

    // Parse last updated date (YYYYDDD format)
    let lastUpdatedSlice = slice(bytes, base, fields.lastUpdated)
    let lastUpdatedComponents = try parseJulianDate(lastUpdatedSlice, lineNumber: lineNumber)

    // Verification status
    let verificationByte = bytes[base + fields.verification.lowerBound]
    let verification: VerificationStatus
    switch verificationByte {
      case ASCII.O: verification = .operational
      case ASCII.U: verification = .underReview
      default:
        throw DOFError.parseError(
          field: "verification",
          value: String(UnicodeScalar(verificationByte)),
          line: lineNumber
        )
    }

    // Single-byte enum fields
    let lightingByte = bytes[base + fields.lighting.lowerBound]
    guard let lighting = LightingType(byte: lightingByte) else {
      throw DOFError.parseError(
        field: "lighting",
        value: String(UnicodeScalar(lightingByte)),
        line: lineNumber
      )
    }

    // AccuracyCategory: space means unknown (category9)
    let accuracyByte = bytes[base + fields.accuracyH.lowerBound]
    guard
      let accuracy = AccuracyCategory(byte: accuracyByte == ASCII.space ? ASCII.nine : accuracyByte)
    else {
      throw DOFError.parseError(
        field: "accuracy",
        value: String(UnicodeScalar(accuracyByte)),
        line: lineNumber
      )
    }

    let actionByte = bytes[base + fields.action.lowerBound]
    guard let action = ActionCode(byte: actionByte) else {
      throw DOFError.parseError(
        field: "action",
        value: String(UnicodeScalar(actionByte)),
        line: lineNumber
      )
    }

    // MarkingType: 'N' and space are aliases for 'A' (none)
    let markingByte = bytes[base + fields.marking.lowerBound]
    let normalizedMarkingByte =
      (markingByte == ASCII.N || markingByte == ASCII.space) ? ASCII.A : markingByte
    guard let marking = MarkingType(byte: normalizedMarkingByte) else {
      throw DOFError.parseError(
        field: "marking",
        value: String(UnicodeScalar(markingByte)),
        line: lineNumber
      )
    }

    // Obstacle type (trimmed string)
    let obstacleType = try slice(bytes, base, fields.obstacleType).toString()

    // Numeric fields
    guard let quantityValue = slice(bytes, base, fields.quantity).parseUInt() else {
      throw DOFError.parseError(field: "quantity", value: "invalid", line: lineNumber)
    }
    let quantity = UInt8(quantityValue)

    guard let agl = slice(bytes, base, fields.aglHeight).parseInt() else {
      throw DOFError.parseError(field: "heightAGL", value: "invalid", line: lineNumber)
    }
    guard let msl = slice(bytes, base, fields.mslHeight).parseInt() else {
      throw DOFError.parseError(field: "heightMSL", value: "invalid", line: lineNumber)
    }

    // Coordinates
    let latitude = try parseLatitude(bytes, base: base, lineNumber: lineNumber)
    let longitude = try parseLongitude(bytes, base: base, lineNumber: lineNumber)

    // State (nil if empty)
    let state: String? = stateSlice.first == ASCII.space ? nil : try stateSlice.toString()

    return Obstacle(
      oasNumber: oasNumber,
      verificationStatus: verification,
      country: country,
      state: state,
      city: city,
      latitudeDeg: latitude,
      longitudeDeg: longitude,
      type: obstacleType,
      quantity: quantity,
      heightFtAGL: agl,
      heightFtMSL: msl,
      lighting: lighting,
      horizontalAccuracy: accuracy,
      marking: marking,
      studyNumber: studyNumber,
      action: action,
      lastUpdatedComponents: lastUpdatedComponents
    )
  }

  /// Parse currency date from the DOF header line.
  /// Expects format: "CURRENCY DATE = MM/DD/YY"
  static func parseCurrencyDate<T: RandomAccessCollection>(
    _ bytes: T
  ) throws -> Cycle where T.Element == UInt8, T.Index == Int {
    // Find pattern
    var matchStart: Int?
    for i in bytes.startIndex..<(bytes.endIndex - currencyDatePattern.count) {
      let slice = bytes[i..<(i + currencyDatePattern.count)]
      guard zip(slice, currencyDatePattern).allSatisfy({ $0 == $1 }) else { continue }
      matchStart = i + currencyDatePattern.count
      break
    }

    guard let start = matchStart else {
      throw DOFError.invalidFormat(.currencyDateHeaderNotFound)
    }

    // Find slash positions in date portion
    let dateBytes = bytes[start...]
    var slashPositions: [Int] = []
    for (i, byte) in dateBytes.enumerated() where byte == ASCII.slash {
      slashPositions.append(start + i)
    }

    guard slashPositions.count >= 2 else {
      throw DOFError.invalidFormat(.invalidCurrencyDateFormat)
    }

    let monthSlice = bytes[start..<slashPositions[0]]
    let daySlice = bytes[(slashPositions[0] + 1)..<slashPositions[1]]
    let yearSlice = bytes[(slashPositions[1] + 1)...]

    guard let month = monthSlice.parseUInt(),
      let day = daySlice.parseUInt(),
      let yearShort = yearSlice.parseUInt()
    else {
      throw DOFError.invalidFormat(.invalidCurrencyDateComponents)
    }

    let year = yearShort < 100 ? 2000 + yearShort : yearShort
    return Cycle(year: year, month: UInt8(month), day: UInt8(day))
  }

  // MARK: Private Helpers

  private static func slice<T: RandomAccessCollection>(
    _ bytes: T,
    _ base: Int,
    _ range: Range<Int>
  ) -> T.SubSequence where T.Index == Int {
    bytes[(base + range.lowerBound)..<(base + range.upperBound)]
  }

  private static func parseLatitude<T: RandomAccessCollection>(
    _ bytes: T,
    base: Int,
    lineNumber: Int
  ) throws -> Double where T.Element == UInt8, T.Index == Int {
    let degSlice = slice(bytes, base, fields.latDegrees)
    let minSlice = slice(bytes, base, fields.latMinutes)
    let secSlice = slice(bytes, base, fields.latSeconds)

    guard let deg = degSlice.parseDouble() else {
      throw DOFError.parseError(
        field: "latDegrees",
        value: try degSlice.toString(),
        line: lineNumber
      )
    }
    guard let min = minSlice.parseDouble() else {
      throw DOFError.parseError(
        field: "latMinutes",
        value: try minSlice.toString(),
        line: lineNumber
      )
    }
    guard let sec = secSlice.dropLast().parseDouble() else {
      throw DOFError.parseError(
        field: "latSeconds",
        value: try secSlice.toString(),
        line: lineNumber
      )
    }

    let decimal = deg + min / 60.0 + sec / 3600.0
    guard let direction = secSlice.last else {
      throw DOFError.parseError(field: "latDirection", value: "missing", line: lineNumber)
    }

    switch direction {
      case ASCII.N: return decimal
      case ASCII.S: return -decimal
      default:
        throw DOFError.invalidFormat(.invalidLatitudeDirection(Character(UnicodeScalar(direction))))
    }
  }

  private static func parseLongitude<T: RandomAccessCollection>(
    _ bytes: T,
    base: Int,
    lineNumber: Int
  ) throws -> Double where T.Element == UInt8, T.Index == Int {
    let degSlice = slice(bytes, base, fields.lonDegrees)
    let minSlice = slice(bytes, base, fields.lonMinutes)
    let secSlice = slice(bytes, base, fields.lonSeconds)

    guard let deg = degSlice.parseDouble() else {
      throw DOFError.parseError(
        field: "lonDegrees",
        value: try degSlice.toString(),
        line: lineNumber
      )
    }
    guard let min = minSlice.parseDouble() else {
      throw DOFError.parseError(
        field: "lonMinutes",
        value: try minSlice.toString(),
        line: lineNumber
      )
    }
    guard let sec = secSlice.dropLast().parseDouble() else {
      throw DOFError.parseError(
        field: "lonSeconds",
        value: try secSlice.toString(),
        line: lineNumber
      )
    }

    let decimal = deg + min / 60.0 + sec / 3600.0
    guard let direction = secSlice.last else {
      throw DOFError.parseError(field: "lonDirection", value: "missing", line: lineNumber)
    }

    switch direction {
      case ASCII.E: return decimal
      case ASCII.W: return -decimal
      default:
        throw DOFError.invalidFormat(
          .invalidLongitudeDirection(Character(UnicodeScalar(direction)))
        )
    }
  }

  /// Parse julian date (YYYYDDD format) into DateComponents.
  private static func parseJulianDate<T: RandomAccessCollection>(
    _ bytes: T,
    lineNumber: Int
  ) throws -> DateComponents where T.Element == UInt8, T.Index == Int {
    // Format: YYYYDDD (e.g., 2014138 = year 2014, day 138)
    let yearSlice = bytes.prefix(4)
    let daySlice = bytes.dropFirst(4)

    guard let year = yearSlice.parseInt() else {
      throw DOFError.parseError(
        field: "lastUpdatedYear",
        value: try yearSlice.toString(),
        line: lineNumber
      )
    }
    guard let dayOfYear = daySlice.parseInt() else {
      throw DOFError.parseError(
        field: "lastUpdatedDay",
        value: try daySlice.toString(),
        line: lineNumber
      )
    }

    var components = DateComponents()
    components.timeZone = .gmt
    components.year = year
    components.dayOfYear = dayOfYear
    return components
  }
}
