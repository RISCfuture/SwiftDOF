import Foundation

/// Obstacle lighting type from the DOF.
///
/// Indicates the type of lighting installed on an obstacle for aviation safety.
public enum LightingType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Red obstruction lights.
  case red = "R"

  /// White strobe lights (high intensity).
  case highIntensityWhite = "H"

  /// White strobe lights (medium intensity).
  case mediumIntensityWhite = "M"

  /// Dual lighting system (red and white).
  case dual = "D"

  /// Low intensity lighting.
  case lowIntensity = "L"

  /// Strobe lights.
  case strobe = "S"

  /// White lights.
  case white = "W"

  /// Flashing lights.
  case flashing = "F"

  /// Catenary lights (typically for power lines).
  case catenary = "C"

  /// Temporary lighting.
  case temporary = "T"

  /// No lighting.
  case none = "N"

  /// Unknown or unspecified lighting.
  case unknown = "U"
}
