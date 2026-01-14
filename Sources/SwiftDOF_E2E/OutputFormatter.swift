import Foundation
import SwiftDOF

/// Protocol for formatting DOF output.
protocol OutputFormatter {
  /// Format and output the DOF data.
  /// - Parameters:
  ///   - dof: The parsed DOF data.
  ///   - errorCount: Number of parse errors encountered.
  ///   - elapsed: Time taken to load and parse.
  ///   - stream: The output stream to write to.
  func format(dof: DOF, errorCount: Int, elapsed: TimeInterval, to stream: OutputStream) throws
}

// MARK: - OutputStream Extension

extension OutputStream {
  func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    data.withUnsafeBytes { buffer in
      guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
      write(pointer, maxLength: buffer.count)
    }
  }

  func writeLine(_ string: String = "") {
    write("\(string)\n")
  }
}

// MARK: - SummaryOutputFormatter

/// Formats DOF data as a human-readable summary.
struct SummaryOutputFormatter: OutputFormatter {
  func format(dof: DOF, errorCount: Int, elapsed _: TimeInterval, to stream: OutputStream) throws {
    stream.writeLine("Cycle: \(dof.cycle)")
    stream.writeLine("Total obstacles: \(dof.count)")
    stream.writeLine("Parse errors: \(errorCount)")
  }
}

// MARK: - JSONOutputFormatter

/// Formats DOF data as JSON output.
struct JSONOutputFormatter: OutputFormatter {
  func format(dof: DOF, errorCount _: Int, elapsed _: TimeInterval, to stream: OutputStream) throws
  {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(dof.all)
    jsonData.withUnsafeBytes { buffer in
      guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
      stream.write(pointer, maxLength: buffer.count)
    }
  }
}
