public import Foundation

/// FAA horizontal accuracy code for an obstacle's reported position.
///
/// The FAA has used these codes since 1979 to declare how tightly an obstacle's
/// location is known. Lower code numbers indicate a more accurate position. A code
/// is typically paired with its ``VerticalAccuracy`` counterpart and spoken as a
/// single accuracy code, such as "1A" or "4D".
public enum HorizontalAccuracy: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// ±20 feet horizontal accuracy.
  case code1 = "1"

  /// ±50 feet horizontal accuracy.
  case code2 = "2"

  /// ±100 feet horizontal accuracy.
  case code3 = "3"

  /// ±250 feet horizontal accuracy.
  case code4 = "4"

  /// ±500 feet horizontal accuracy.
  case code5 = "5"

  /// ±1,000 feet horizontal accuracy.
  case code6 = "6"

  /// ±0.5 nautical mile horizontal accuracy.
  case code7 = "7"

  /// ±1 nautical mile horizontal accuracy.
  case code8 = "8"

  /// Unknown accuracy.
  case code9 = "9"

  /// The tolerance this code guarantees, or `nil` when the accuracy is unknown.
  public var tolerance: Measurement<UnitLength>? {
    switch self {
      case .code1: .init(value: 20, unit: .feet)
      case .code2: .init(value: 50, unit: .feet)
      case .code3: .init(value: 100, unit: .feet)
      case .code4: .init(value: 250, unit: .feet)
      case .code5: .init(value: 500, unit: .feet)
      case .code6: .init(value: 1000, unit: .feet)
      case .code7: .init(value: 0.5, unit: .nauticalMiles)
      case .code8: .init(value: 1, unit: .nauticalMiles)
      case .code9: nil
    }
  }
}
