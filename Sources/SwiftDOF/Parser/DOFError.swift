import Foundation

/// Specific format errors that can occur during DOF parsing.
public enum DOFFormatError: Sendable {
  /// The currency date header line was not found.
  case missingCurrencyDate

  /// The currency date pattern "CURRENCY DATE = " was not found.
  case currencyDateHeaderNotFound

  /// The currency date is not in MM/DD/YY format.
  case invalidCurrencyDateFormat

  /// The currency date components could not be parsed as numbers.
  case invalidCurrencyDateComponents

  /// The latitude direction is not N or S.
  case invalidLatitudeDirection(Character)

  /// The longitude direction is not E or W.
  case invalidLongitudeDirection(Character)
}

/// Errors that can occur during DOF parsing.
public enum DOFError: Error, LocalizedError, Sendable {
  /// The file data is not valid Latin-1 encoding.
  case invalidEncoding

  /// The file format is invalid.
  case invalidFormat(DOFFormatError)

  /// A field could not be parsed.
  case parseError(field: String, value: String, line: Int)

  /// The file was not found.
  case fileNotFound(URL)

  /// An error occurred while reading the stream.
  case streamError(Error)

  /// The line is too short to parse.
  case lineTooShort(expected: Int, actual: Int, line: Int)

  public var errorDescription: String? {
    switch self {
      case .invalidEncoding:
        #if canImport(Darwin)
          String(localized: "File encoding was invalid.", bundle: .module)
        #else
          "File encoding was invalid."
        #endif
      case .invalidFormat:
        #if canImport(Darwin)
          String(localized: "DOF data format was invalid.", bundle: .module)
        #else
          "DOF data format was invalid."
        #endif
      case .parseError:
        #if canImport(Darwin)
          String(localized: "DOF data could not be parsed.", bundle: .module)
        #else
          "DOF data could not be parsed."
        #endif
      case .fileNotFound:
        #if canImport(Darwin)
          String(localized: "DOF file was not found.", bundle: .module)
        #else
          "DOF file was not found."
        #endif
      case .streamError:
        #if canImport(Darwin)
          String(localized: "A stream error occurred.", bundle: .module)
        #else
          "A stream error occurred."
        #endif
      case .lineTooShort:
        #if canImport(Darwin)
          String(localized: "Line was too short.", bundle: .module)
        #else
          "Line was too short."
        #endif
    }
  }

  public var failureReason: String? {
    switch self {
      case .invalidEncoding:
        #if canImport(Darwin)
          String(localized: "The file is not valid Latin-1 encoding.", bundle: .module)
        #else
          "The file is not valid Latin-1 encoding."
        #endif
      case .invalidFormat(let error):
        switch error {
          case .missingCurrencyDate:
            #if canImport(Darwin)
              String(localized: "The DOF header does not contain a currency date.", bundle: .module)
            #else
              "The DOF header does not contain a currency date."
            #endif
          case .currencyDateHeaderNotFound:
            #if canImport(Darwin)
              String(
                localized: "The “CURRENCY DATE = ” pattern was not found in the header.",
                bundle: .module
              )
            #else
              "The “CURRENCY DATE = ” pattern was not found in the header."
            #endif
          case .invalidCurrencyDateFormat:
            #if canImport(Darwin)
              String(localized: "The currency date is not in MM/DD/YY format.", bundle: .module)
            #else
              "The currency date is not in MM/DD/YY format."
            #endif
          case .invalidCurrencyDateComponents:
            #if canImport(Darwin)
              String(
                localized: "The currency date contains non-numeric components.",
                bundle: .module
              )
            #else
              "The currency date contains non-numeric components."
            #endif
          case .invalidLatitudeDirection(let char):
            #if canImport(Darwin)
              String(
                localized: "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”.",
                bundle: .module
              )
            #else
              "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”."
            #endif
          case .invalidLongitudeDirection(let char):
            #if canImport(Darwin)
              String(
                localized: "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”.",
                bundle: .module
              )
            #else
              "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”."
            #endif
        }
      case let .parseError(field, value, line):
        #if canImport(Darwin)
          String(localized: "Failed to parse \(field) “\(value)” at line \(line).", bundle: .module)
        #else
          "Failed to parse \(field) “\(value)” at line \(line)."
        #endif
      case .fileNotFound(let url):
        #if canImport(Darwin)
          String(localized: "The file at “\(url.path)” could not be found.", bundle: .module)
        #else
          "The file at “\(url.path)” could not be found."
        #endif
      case .streamError(let error):
        #if canImport(Darwin)
          String(
            localized: "An error occurred while reading: \(error.localizedDescription)",
            bundle: .module
          )
        #else
          "An error occurred while reading: \(error.localizedDescription)"
        #endif
      case let .lineTooShort(expected, actual, line):
        #if canImport(Darwin)
          String(
            localized: "Line \(line) has \(actual) characters but \(expected) are required.",
            bundle: .module
          )
        #else
          "Line \(line) has \(actual) characters but \(expected) are required."
        #endif
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidEncoding, .invalidFormat:
        #if canImport(Darwin)
          String(
            localized: "Verify the file is a valid FAA Digital Obstacle File.",
            bundle: .module
          )
        #else
          "Verify the file is a valid FAA Digital Obstacle File."
        #endif
      case .fileNotFound:
        #if canImport(Darwin)
          String(
            localized: "Verify that the file exists and has not been moved or deleted.",
            bundle: .module
          )
        #else
          "Verify that the file exists and has not been moved or deleted."
        #endif
      case .parseError, .streamError, .lineTooShort:
        nil
    }
  }
}
