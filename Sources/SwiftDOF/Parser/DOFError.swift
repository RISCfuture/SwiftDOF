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
        String(localized: "File encoding was invalid.", bundle: .module)
      case .invalidFormat:
        String(localized: "DOF data format was invalid.", bundle: .module)
      case .parseError:
        String(localized: "DOF data could not be parsed.", bundle: .module)
      case .fileNotFound:
        String(localized: "DOF file was not found.", bundle: .module)
      case .streamError:
        String(localized: "A stream error occurred.", bundle: .module)
      case .lineTooShort:
        String(localized: "Line was too short.", bundle: .module)
    }
  }

  public var failureReason: String? {
    switch self {
      case .invalidEncoding:
        String(localized: "The file is not valid Latin-1 encoding.", bundle: .module)
      case .invalidFormat(let error):
        switch error {
          case .missingCurrencyDate:
            String(localized: "The DOF header does not contain a currency date.", bundle: .module)
          case .currencyDateHeaderNotFound:
            String(
              localized: "The “CURRENCY DATE = ” pattern was not found in the header.",
              bundle: .module
            )
          case .invalidCurrencyDateFormat:
            String(localized: "The currency date is not in MM/DD/YY format.", bundle: .module)
          case .invalidCurrencyDateComponents:
            String(localized: "The currency date contains non-numeric components.", bundle: .module)
          case .invalidLatitudeDirection(let char):
            String(
              localized: "Latitude direction “\(String(char))” is invalid. Expected “N” or “S”.",
              bundle: .module
            )
          case .invalidLongitudeDirection(let char):
            String(
              localized: "Longitude direction “\(String(char))” is invalid. Expected “E” or “W”.",
              bundle: .module
            )
        }
      case let .parseError(field, value, line):
        String(localized: "Failed to parse \(field) “\(value)” at line \(line).", bundle: .module)
      case .fileNotFound(let url):
        String(localized: "The file at “\(url.path)” could not be found.", bundle: .module)
      case .streamError(let error):
        String(
          localized: "An error occurred while reading: \(error.localizedDescription)",
          bundle: .module
        )
      case let .lineTooShort(expected, actual, line):
        String(
          localized: "Line \(line) has \(actual) characters but \(expected) are required.",
          bundle: .module
        )
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidEncoding, .invalidFormat:
        String(localized: "Verify the file is a valid FAA Digital Obstacle File.", bundle: .module)
      case .fileNotFound:
        String(
          localized: "Verify that the file exists and has not been moved or deleted.",
          bundle: .module
        )
      case .parseError, .streamError, .lineTooShort:
        nil
    }
  }
}
