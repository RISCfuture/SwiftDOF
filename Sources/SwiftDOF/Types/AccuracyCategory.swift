import Foundation

/// FAA horizontal accuracy category for obstacle position data.
///
/// Categories 1-9 and A indicate the accuracy of the obstacle's reported position.
/// Lower numbers indicate higher accuracy.
public enum AccuracyCategory: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Survey data accuracy (approximately ±3 feet).
  case survey = "A"

  /// ±20 feet horizontal accuracy.
  case category1 = "1"

  /// ±50 feet horizontal accuracy.
  case category2 = "2"

  /// ±100 feet horizontal accuracy.
  case category3 = "3"

  /// ±250 feet horizontal accuracy.
  case category4 = "4"

  /// ±500 feet horizontal accuracy.
  case category5 = "5"

  /// ±1,000 feet horizontal accuracy.
  case category6 = "6"

  /// ±0.5 nautical mile horizontal accuracy.
  case category7 = "7"

  /// ±1 nautical mile horizontal accuracy.
  case category8 = "8"

  /// Unknown accuracy.
  case category9 = "9"

  /// Approximate accuracy, if known.
  public var accuracy: Measurement<UnitLength>? {
    switch self {
      case .survey: .init(value: 3, unit: .feet)
      case .category1: .init(value: 20, unit: .feet)
      case .category2: .init(value: 50, unit: .feet)
      case .category3: .init(value: 100, unit: .feet)
      case .category4: .init(value: 250, unit: .feet)
      case .category5: .init(value: 500, unit: .feet)
      case .category6: .init(value: 1000, unit: .feet)
      case .category7: .init(value: 0.5, unit: .nauticalMiles)
      case .category8: .init(value: 1, unit: .nauticalMiles)
      case .category9: nil
    }
  }
}
