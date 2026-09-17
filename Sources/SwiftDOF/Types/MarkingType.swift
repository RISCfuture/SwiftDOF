import Foundation

/// Obstacle mark indicator from the DOF.
///
/// Indicates how an obstacle is marked for visibility to aircraft.
public enum MarkingType: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Marked with orange, or orange and white, paint.
  case orangeOrOrangeWhitePaint = "P"

  /// Marked with white paint only.
  case whitePaintOnly = "W"

  /// Marked, by a means the DOF does not identify.
  case marked = "M"

  /// Marked with flag markers.
  case flagMarker = "F"

  /// Marked with spherical markers (typically on power lines).
  case sphericalMarker = "S"

  /// Not marked.
  case none = "N"

  /// Marking unknown.
  case unknown = "U"
}
