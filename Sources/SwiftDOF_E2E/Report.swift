import Foundation
import SwiftDOF

/// A machine-readable record of one end-to-end parse, written with `--report`.
///
/// The report is what the cycle-watch workflow reads to decide whether a cycle parsed cleanly,
/// and it doubles as the baseline the next cycle is compared against.
struct Report: Codable {

  /// The share of the total obstacle count that may change between cycles before it counts as
  /// drift. Obstacle data turns over slowly; a swing this large is a parsing problem, not news.
  private static let totalDriftTolerance = 0.05

  /// The share of a single region's obstacle count that may change between cycles. Regions are
  /// small enough to be noisier than the file as a whole.
  private static let regionDriftTolerance = 0.10

  /// The greatest number of parse errors quoted in the report.
  private static let maximumErrorSamples = 50

  /// The cycle the parsed file declares in its currency date header.
  let cycle: String

  /// Where the data was read from.
  let source: String

  /// The number of obstacles parsed.
  let obstacleCount: Int

  /// The number of lines that failed to parse.
  let parseErrorCount: Int

  /// How long loading and parsing took, in seconds.
  let elapsed: TimeInterval

  /// Obstacle counts keyed by region, as `COUNTRY-STATE` or bare `COUNTRY` where the DOF carries
  /// no state. The country is always part of the key because state and country codes collide —
  /// `CA` is both California and Canada.
  let countsByRegion: [String: Int]

  /// Up to ``maximumErrorSamples`` of the parse errors.
  let errorSamples: [ErrorSample]

  /// Whether this cycle failed its check.
  let failed: Bool

  /// Why the cycle failed, empty when it did not.
  let failureReasons: [String]

  /// Counts that moved more than their tolerance against the baseline.
  let drift: [Drift]

  /// Builds a report from a completed parse, optionally compared against an earlier cycle's report.
  init(
    dof: DOF,
    source: String,
    parseErrorCount: Int,
    errorSamples: [ErrorSample],
    elapsed: TimeInterval,
    baseline: Self?
  ) {
    let countsByRegion = Self.countsByRegion(of: dof)

    self.cycle = dof.cycle.id
    self.source = source
    self.obstacleCount = dof.count
    self.parseErrorCount = parseErrorCount
    self.elapsed = elapsed
    self.countsByRegion = countsByRegion
    self.errorSamples = Array(errorSamples.prefix(Self.maximumErrorSamples))
    self.failureReasons = Self.failureReasons(
      obstacleCount: dof.count,
      parseErrorCount: parseErrorCount
    )
    self.failed = !failureReasons.isEmpty
    self.drift =
      baseline.map {
        Self.drift(from: $0, totalNow: dof.count, regionsNow: countsByRegion)
      } ?? []
  }

  /// Reads a report written by an earlier run.
  static func read(from url: URL) throws -> Self {
    try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
  }

  /// Obstacle counts keyed by country and state, so that California and Canada stay apart.
  private static func countsByRegion(of dof: DOF) -> [String: Int] {
    dof.reduce(into: [:]) { counts, obstacle in
      counts[regionKey(of: obstacle), default: 0] += 1
    }
  }

  private static func regionKey(of obstacle: Obstacle) -> String {
    guard let state = obstacle.state else { return obstacle.country }
    return "\(obstacle.country)-\(state)"
  }

  private static func failureReasons(obstacleCount: Int, parseErrorCount: Int) -> [String] {
    var reasons: [String] = []
    if parseErrorCount > 0 {
      reasons.append("\(parseErrorCount) line(s) failed to parse.")
    }
    if obstacleCount == 0 {
      reasons.append("The file parsed to zero obstacles.")
    }
    return reasons
  }

  private static func drift(
    from baseline: Self,
    totalNow: Int,
    regionsNow: [String: Int]
  ) -> [Drift] {
    var drift: [Drift] = []

    if let total = Drift(
      scope: "total",
      was: baseline.obstacleCount,
      now: totalNow,
      tolerance: totalDriftTolerance
    ) {
      drift.append(total)
    }

    for (region, was) in baseline.countsByRegion.sorted(by: { $0.key < $1.key }) {
      if let regionDrift = Drift(
        scope: region,
        was: was,
        now: regionsNow[region],
        tolerance: regionDriftTolerance
      ) {
        drift.append(regionDrift)
      }
    }

    return drift
  }

  /// One parse error, quoted for the report.
  struct ErrorSample: Codable {
    /// The line the error was reported on.
    let line: Int

    /// The error's general description.
    let message: String

    /// Which field failed and why, when the error carries that detail.
    let reason: String?

    init(line: Int, error: any Error) {
      self.line = line
      self.message = error.localizedDescription
      self.reason = (error as? (any LocalizedError))?.failureReason
    }
  }

  /// A count that moved more than its tolerance between two cycles.
  struct Drift: Codable {
    /// What the count covers: `total`, or a region key from ``Report/countsByRegion``.
    let scope: String

    /// The count in the baseline cycle.
    let was: Int

    /// The count in this cycle, or `nil` when the scope vanished entirely.
    let now: Int?

    /// Why the movement was recorded.
    let reason: String

    /// Records drift, or returns `nil` when the count held within `tolerance`.
    init?(scope: String, was: Int, now: Int?, tolerance: Double) {
      guard let now else {
        self.init(scope: scope, was: was, now: nil, reason: "The region is no longer present.")
        return
      }

      guard was > 0 else { return nil }

      let change = Double(now - was) / Double(was)
      guard abs(change) > tolerance else { return nil }

      let percent = (abs(change) * 100).formatted(.number.precision(.fractionLength(1)))
      self.init(
        scope: scope,
        was: was,
        now: now,
        reason: "The count \(change < 0 ? "fell" : "rose") by \(percent)%."
      )
    }

    private init(scope: String, was: Int, now: Int?, reason: String) {
      self.scope = scope
      self.was = was
      self.now = now
      self.reason = reason
    }
  }
}
