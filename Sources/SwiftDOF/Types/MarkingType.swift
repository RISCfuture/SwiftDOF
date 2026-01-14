import Foundation

/// Obstacle marking indicator from the DOF.
///
/// Indicates how an obstacle is marked for visibility to aircraft.
public enum MarkingType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// No marking or unknown.
  case none = "A"

  /// Marked with high visibility orange and white paint.
  case orangeWhitePaint = "B"

  /// Marked with flag markers.
  case flagMarkers = "C"

  /// Marked with orange and white paint and has flag markers.
  case paintAndFlags = "D"

  /// Marked with high visibility lighting only.
  case lightingOnly = "E"

  /// Marked with orange and white paint and high visibility lighting.
  case paintAndLighting = "F"

  /// Marked with flag markers and high visibility lighting.
  case flagsAndLighting = "G"

  /// Marked with orange and white paint, flag markers, and high visibility lighting.
  case paintFlagsAndLighting = "H"

  /// Marked with spherical markers (typically on power lines).
  case sphericalMarkers = "I"
}
