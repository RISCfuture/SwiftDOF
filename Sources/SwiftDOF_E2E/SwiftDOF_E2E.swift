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

  @Option(
    name: .long,
    help: "Path to write a JSON report of the parse to",
    completion: .file(extensions: ["json"]),
    transform: { URL(filePath: $0) }
  )
  var report: URL?

  @Option(
    name: .long,
    help: "Path to an earlier report to compare counts against",
    completion: .file(extensions: ["json"]),
    transform: { URL(filePath: $0) }
  )
  var baseline: URL?

  private var currentCycleURL: URL {
    get throws {
      let cycle = Cycle.effective
      guard let components = cycle.lastDateComponents else {
        throw ValidationError("Failed to calculate cycle date")
      }
      guard let year = components.year, let month = components.month, let day = components.day
      else {
        fatalError("Current cycle could not be determined")
      }
      let filename = unsafe String(format: "DOF_%02d%02d%02d.zip", year % 100, month, day)
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
    var errorSamples: [Report.ErrorSample] = []
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
        errorSamples.append(.init(line: line, error: error))
        var message = "Error at line \(line): \(error.localizedDescription)"
        if let reason = (error as? (any LocalizedError))?.failureReason {
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

    if let report {
      try writeReport(
        to: report,
        dof: dof,
        source: inputURL,
        errorCount: errorCount,
        errorSamples: errorSamples,
        elapsed: elapsed
      )
    }

    if errorCount > 0 {
      throw ExitCode.failure
    }
  }

  /// Writes the JSON report, comparing counts against `baseline` when one was given.
  private func writeReport(
    to url: URL,
    dof: DOF,
    source: URL,
    errorCount: Int,
    errorSamples: [Report.ErrorSample],
    elapsed: TimeInterval
  ) throws {
    let report = Report(
      dof: dof,
      source: source.absoluteString,
      parseErrorCount: errorCount,
      errorSamples: errorSamples,
      elapsed: elapsed,
      baseline: try baseline.map { try Report.read(from: $0) }
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(report).write(to: url)
  }

  private func makeLoader(for url: URL) -> any DOFDataLoader {
    if url.isFileURL {
      return FileDataLoader(url: url)
    }
    if url.pathExtension.lowercased() == "zip" {
      return URLZipLoader(url: url)
    }
    return URLStreamLoader(url: url)
  }

  private func makeFormatter(for format: OutputFormat) -> any OutputFormatter {
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
///
/// Polls `fractionCompleted` on a timer rather than observing it via KVO, since
/// `NSKeyValueObservation` requires the Objective-C runtime and isn't available on Linux.
private actor ProgressTracker {
  private var bar: ProgressBar?
  private var pollTask: Task<Void, Never>?
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

    pollTask = Task {
      while !Task.isCancelled, !progress.isFinished {
        advanceTo(Int(progress.fractionCompleted * 100))
        try? await Task.sleep(for: .milliseconds(50))
      }
      advanceTo(Int(progress.fractionCompleted * 100))
    }
  }

  private func advanceTo(_ step: Int) {
    while lastStep < step {
      bar?.next()
      lastStep += 1
    }
  }

  func stop() {
    pollTask?.cancel()
    pollTask = nil
    // Ensure bar reaches 100%
    advanceTo(100)
  }
}
