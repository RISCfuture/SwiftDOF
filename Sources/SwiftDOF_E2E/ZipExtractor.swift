import Foundation
import ZIPFoundation

/// Utility for extracting DOF data from ZIP archives.
enum ZipExtractor {

  /// Extract DOF.DAT from a ZIP file at the given URL.
  static func extractDOFData(from url: URL) throws -> Data {
    let zipData = try Data(contentsOf: url)
    return try extractDOFData(from: zipData)
  }

  /// Extract DOF.DAT from ZIP data using ZIPFoundation.
  static func extractDOFData(from zipData: Data) throws -> Data {
    let archive = try Archive(data: zipData, accessMode: .read)

    // Find DOF.DAT (case-insensitive)
    if let entry = archive.first(where: { $0.path.uppercased() == "DOF.DAT" }) {
      return try extractEntry(entry, from: archive)
    }

    // Try looking for any .DAT file
    if let entry = archive.first(where: { $0.path.uppercased().hasSuffix(".DAT") }) {
      return try extractEntry(entry, from: archive)
    }

    throw ZipExtractorError.dofNotFound
  }

  private static func extractEntry(_ entry: Entry, from archive: Archive) throws -> Data {
    var result = Data()
    _ = try archive.extract(entry) { data in
      result.append(data)
    }
    return result
  }
}

/// Errors that can occur during ZIP extraction.
enum ZipExtractorError: Error, LocalizedError, Sendable {
  /// The ZIP archive format is invalid or corrupted.
  case invalidZipFormat

  /// The DOF.DAT file was not found in the ZIP archive.
  case dofNotFound

  var errorDescription: String? {
    switch self {
      case .invalidZipFormat:
        "ZIP archive format was invalid."
      case .dofNotFound:
        "DOF data was not found in archive."
    }
  }

  var failureReason: String? {
    switch self {
      case .invalidZipFormat:
        "The file is not a valid ZIP archive or may be corrupted."
      case .dofNotFound:
        "The ZIP archive does not contain a DOF.DAT file."
    }
  }

  var recoverySuggestion: String? {
    switch self {
      case .invalidZipFormat, .dofNotFound:
        "Verify the file is a valid ZIP archive from the FAA."
    }
  }
}
