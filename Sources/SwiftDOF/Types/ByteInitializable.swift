import Foundation

/// Protocol for Character-based enums that can be initialized from an ASCII byte.
protocol ByteInitializable: RawRepresentable where RawValue == Character {
  init?(byte: UInt8)
}

extension ByteInitializable {
  /// Initialize from an ASCII byte value.
  init?(byte: UInt8) {
    self.init(rawValue: Character(UnicodeScalar(byte)))
  }
}
