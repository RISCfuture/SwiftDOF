import Foundation
import SwiftDOF

/// Protocol for loading DOF data from various sources.
protocol DOFDataLoader {
  /// Load DOF data from the source.
  /// - Parameter errorCallback: Called for each parse error with (error, lineNumber).
  /// - Returns: The parsed DOF data.
  func load(errorCallback: @escaping (Error, Int) -> Void) async throws -> DOF
}

// MARK: - FileDataLoader

/// Loads DOF data from a local file (supports both .dat and .zip).
struct FileDataLoader: DOFDataLoader {
  let url: URL

  func load(errorCallback: @escaping (Error, Int) -> Void) throws -> DOF {
    let data: Data
    if url.pathExtension.lowercased() == "zip" {
      data = try ZipExtractor.extractDOFData(from: url)
    } else {
      data = try Data(contentsOf: url)
    }

    guard let dof = DOF.from(data: data, errorCallback: errorCallback) else {
      throw DOFDataLoaderError.parseFailed
    }
    return dof
  }
}

// MARK: - URLZipLoader

/// Downloads a ZIP file from a remote URL, extracts, and parses DOF data.
struct URLZipLoader: DOFDataLoader {
  let url: URL

  func load(errorCallback: @escaping (Error, Int) -> Void) async throws -> DOF {
    let (downloadedData, response) = try await URLSession.shared.data(from: url)

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
      throw DOFDataLoaderError.downloadFailed(statusCode: httpResponse.statusCode)
    }

    let data = try ZipExtractor.extractDOFData(from: downloadedData)

    guard let dof = DOF.from(data: data, errorCallback: errorCallback) else {
      throw DOFDataLoaderError.parseFailed
    }
    return dof
  }
}

// MARK: - URLStreamLoader

/// Streams DOF data directly from a remote URL using async bytes.
struct URLStreamLoader: DOFDataLoader {
  let url: URL

  func load(errorCallback: @escaping (Error, Int) -> Void) async throws -> DOF {
    let (bytes, response) = try await URLSession.shared.bytes(from: url)

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
      throw DOFDataLoaderError.downloadFailed(statusCode: httpResponse.statusCode)
    }

    return try await DOF(bytes: bytes, errorCallback: errorCallback)
  }
}

// MARK: - Errors

/// Errors that can occur during DOF data loading.
enum DOFDataLoaderError: LocalizedError {
  case downloadFailed(statusCode: Int)
  case parseFailed

  var errorDescription: String? {
    switch self {
      case .downloadFailed(let statusCode):
        return "Download failed with status code: \(statusCode)"
      case .parseFailed:
        return "Failed to parse DOF data"
    }
  }
}
