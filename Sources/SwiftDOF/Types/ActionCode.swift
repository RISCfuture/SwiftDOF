import Foundation

/// Action code indicating the status of a DOF record.
///
/// Indicates whether the record is active or has been changed since the last publication.
public enum ActionCode: Character, Sendable, Codable, CaseIterable, ByteInitializable {
  /// Record is active/new.
  case active = "A"

  /// Record has been changed since last publication.
  case changed = "C"
}
