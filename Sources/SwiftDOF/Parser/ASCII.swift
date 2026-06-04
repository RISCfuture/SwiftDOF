import Foundation

/// ASCII byte constants for efficient byte-level parsing.
@usableFromInline
enum ASCII {
  @usableFromInline static let LF: UInt8 = 0x0A  // '\n'
  @usableFromInline static let CR: UInt8 = 0x0D  // '\r'
  @usableFromInline static let space: UInt8 = 0x20  // ' '
  @usableFromInline static let minus: UInt8 = 0x2D  // '-'
  @usableFromInline static let dot: UInt8 = 0x2E  // '.'
  @usableFromInline static let slash: UInt8 = 0x2F  // '/'
  @usableFromInline static let zero: UInt8 = 0x30  // '0'
  @usableFromInline static let nine: UInt8 = 0x39  // '9'
  @usableFromInline static let A: UInt8 = 0x41
  @usableFromInline static let E: UInt8 = 0x45
  @usableFromInline static let N: UInt8 = 0x4E
  @usableFromInline static let O: UInt8 = 0x4F
  @usableFromInline static let S: UInt8 = 0x53
  @usableFromInline static let U: UInt8 = 0x55
  @usableFromInline static let W: UInt8 = 0x57

  @inlinable
  static func isDigit(_ byte: UInt8) -> Bool {
    byte >= zero && byte <= nine
  }

  @inlinable
  static func digitValue(_ byte: UInt8) -> Int {
    Int(byte - zero)
  }
}
