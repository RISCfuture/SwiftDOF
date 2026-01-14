import Foundation
import ArgumentParser
import SwiftDOF

@main
struct SwiftDOF_E2E: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "SwiftDOF_E2E",
    abstract: "Parse and validate FAA Digital Obstacle File data",
    discussion: """
      Parses DOF data from a local file or downloads the current cycle from the FAA website.
      Errors encountered during parsing are printed to stderr.
      """
  )

  @Option(
    name: .shortAndLong,
    help: "Path or URL to DOF file (.dat or .zip)",
    completion: .file(extensions: ["dat", "zip"]),
    transform: { str in
      // Try parsing as URL first - if it has a non-file scheme, use it
      if let url = URL(string: str), !url.isFileURL, url.scheme != nil {
        return url
      }
      // Otherwise treat as file path
      return URL(filePath: str)
    }
  )
  var input: URL?

  @Option(name: .shortAndLong, help: "Output format: summary or json")
  var format: OutputFormat = .summary

  private var currentCycleURL: URL {
    get throws {
      let cycle = Cycle.current
      guard let components = cycle.lastDateComponents else {
        throw ValidationError("Failed to calculate cycle date")
      }
      guard let year = components.year, let month = components.month, let day = components.day
      else {
        fatalError("Current cycle could not be determined")
      }
      let filename = String(format: "DOF_%02d%02d%02d.zip", year % 100, month, day)
      guard let url = URL(string: "https://aeronav.faa.gov/Obst_Data/\(filename)") else {
        fatalError("Current DOF URL could not be determined")
      }
      return url
    }
  }

  mutating func run() async throws {
    let inputURL = try input ?? currentCycleURL
    let loader = makeLoader(for: inputURL)
    let formatter = makeFormatter(for: format)

    var errorCount = 0
    let startTime = Date()

    let dof = try await loader.load { error, line in
      errorCount += 1
      var message = "Error at line \(line): \(error.localizedDescription)"
      if let reason = (error as? LocalizedError)?.failureReason {
        message += "\n - \(reason)"
      }
      FileHandle.standardError.write(Data("\(message)\n".utf8))
    }

    let elapsed = Date().timeIntervalSince(startTime)

    guard let stdout = OutputStream(toFileAtPath: "/dev/stdout", append: false) else {
      fatalError("Failed to open stdout")
    }
    stdout.open()
    defer { stdout.close() }

    try formatter.format(dof: dof, errorCount: errorCount, elapsed: elapsed, to: stdout)
  }

  private func makeLoader(for url: URL) -> DOFDataLoader {
    if url.isFileURL {
      return FileDataLoader(url: url)
    }
    if url.pathExtension.lowercased() == "zip" {
      return URLZipLoader(url: url)
    }
    return URLStreamLoader(url: url)
  }

  private func makeFormatter(for format: OutputFormat) -> OutputFormatter {
    switch format {
      case .summary: return SummaryOutputFormatter()
      case .json: return JSONOutputFormatter()
    }
  }

  enum OutputFormat: String, ExpressibleByArgument {
    case summary
    case json
  }
}
