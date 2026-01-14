import Foundation

/// Verification status of obstacle data in the DOF.
///
/// Indicates whether the obstacle data has been verified by the FAA.
public enum VerificationStatus: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Obstacle data has been verified as operational.
  case operational = "O"

  /// Obstacle data is under review and has not been verified.
  case underReview = "U"
}
