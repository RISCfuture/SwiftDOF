import Foundation
import ArgumentParser
import Progress
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
    let showProgress = format != .json

    // Set up progress tracking using actor to safely hold observation
    let progressTracker = showProgress ? ProgressTracker() : nil

    let dof = try await loader.load(
      progressHandler: { progress in
        if let tracker = progressTracker {
          Task { await tracker.track(progress) }
        }
      },
      errorCallback: { error, line in
        errorCount += 1
        var message = "Error at line \(line): \(error.localizedDescription)"
        if let reason = (error as? LocalizedError)?.failureReason {
          message += "\n - \(reason)"
        }
        FileHandle.standardError.write(Data("\(message)\n".utf8))
      }
    )

    // Clean up observation
    if let tracker = progressTracker {
      await tracker.stop()
      print()  // Move to next line after progress bar
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

// MARK: - ProgressTracker

/// Actor to safely track progress using Progress.swift library.
private actor ProgressTracker {
  private var bar: ProgressBar?
  private var observation: NSKeyValueObservation?
  private var lastStep = 0

  func track(_ progress: Foundation.Progress) {
    bar = ProgressBar(
      count: 100,
      configuration: [
        ProgressString(string: "Parsing:"),
        ProgressBarLine(barLength: 40),
        ProgressPercent()
      ]
    )

    observation = progress.observe(\.fractionCompleted, options: [.new]) { [self] progress, _ in
      let currentStep = Int(progress.fractionCompleted * 100)
      Task { await self.advanceTo(currentStep) }
    }
  }

  private func advanceTo(_ step: Int) {
    while lastStep < step {
      bar?.next()
      lastStep += 1
    }
  }

  func stop() {
    observation?.invalidate()
    observation = nil
    // Ensure bar reaches 100%
    advanceTo(100)
  }
}
