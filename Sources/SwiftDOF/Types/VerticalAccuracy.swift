public import Foundation

/// FAA vertical accuracy code for an obstacle's reported height.
///
/// The FAA has used these codes since 1979 to declare how tightly an obstacle's
/// height is known. Earlier code letters indicate a more accurate height. A code
/// is typically paired with its ``HorizontalAccuracy`` counterpart and spoken as a
/// single accuracy code, such as "1A" or "4D".
public enum VerticalAccuracy: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// ±3 feet vertical accuracy.
  case codeA = "A"

  /// ±10 feet vertical accuracy.
  case codeB = "B"

  /// ±20 feet vertical accuracy.
  case codeC = "C"

  /// ±50 feet vertical accuracy.
  case codeD = "D"

  /// ±125 feet vertical accuracy.
  case codeE = "E"

  /// ±250 feet vertical accuracy.
  case codeF = "F"

  /// ±500 feet vertical accuracy.
  case codeG = "G"

  /// ±1,000 feet vertical accuracy.
  case codeH = "H"

  /// Unknown accuracy.
  case codeI = "I"

  /// The tolerance this code guarantees, or `nil` when the accuracy is unknown.
  public var tolerance: Measurement<UnitLength>? {
    switch self {
      case .codeA: .init(value: 3, unit: .feet)
      case .codeB: .init(value: 10, unit: .feet)
      case .codeC: .init(value: 20, unit: .feet)
      case .codeD: .init(value: 50, unit: .feet)
      case .codeE: .init(value: 125, unit: .feet)
      case .codeF: .init(value: 250, unit: .feet)
      case .codeG: .init(value: 500, unit: .feet)
      case .codeH: .init(value: 1000, unit: .feet)
      case .codeI: nil
    }
  }
}
