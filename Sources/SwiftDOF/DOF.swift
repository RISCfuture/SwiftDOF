import Foundation

/// Container for DOF obstacle data.
///
/// The DOF struct parses and stores obstacle data from FAA Digital Obstacle Files.
/// It provides efficient lookup by OAS number and iteration over all obstacles.
public struct DOF: Sendable, Codable {

  /// Estimated number of obstacles for pre-allocation.
  private static let estimatedObstacleCount = 650_000

  /// Obstacles stored by OAS number for O(1) lookup.
  private var obstaclesByID: [String: Obstacle]

  /// The cycle (effective date) of this DOF data.
  public let cycle: Cycle

  /// The total number of obstacles.
  public var count: Int { obstaclesByID.count }

  /// All obstacles (unordered). This initializes a new array in memory.
  public var all: [Obstacle] { Array(obstaclesByID.values) }

  // MARK: - Initialization

  /// Creates a DOF container by parsing the given data.
  ///
  /// Uses streaming byte-based parsing for optimal performance.
  ///
  /// - Parameters:
  ///   - data: The DOF file content as raw bytes.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber).
  /// - Throws: DOFError if the file format is invalid.
  public init(data: Data, errorCallback: ((Error, Int) -> Void)? = nil) throws {
    var obstacles: [String: Obstacle] = [:]
    obstacles.reserveCapacity(Self.estimatedObstacleCount)

    var lineNumber = 0
    var cycle: Cycle?

    for line in DOFLineReader(data: data) {
      lineNumber += 1
      try Self.processLine(
        line,
        lineNumber: lineNumber,
        cycle: &cycle,
        obstacles: &obstacles,
        errorCallback: errorCallback
      )
    }

    guard let cycle else {
      throw DOFError.invalidFormat(.missingCurrencyDate)
    }

    self.cycle = cycle
    self.obstaclesByID = obstacles
  }

  /// Creates a DOF container by streaming from a file URL.
  ///
  /// Uses async streaming for efficient memory usage with large files.
  ///
  /// - Parameters:
  ///   - url: The URL of the DOF file to parse.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber).
  /// - Throws: DOFError if the file format is invalid.
  public init(url: URL, errorCallback: ((Error, Int) -> Void)? = nil) async throws {
    var obstacles: [String: Obstacle] = [:]
    obstacles.reserveCapacity(Self.estimatedObstacleCount)

    var lineNumber = 0
    var cycle: Cycle?

    for try await line in AsyncDOFLineReader(url: url) {
      lineNumber += 1
      try Self.processLine(
        line[...],
        lineNumber: lineNumber,
        cycle: &cycle,
        obstacles: &obstacles,
        errorCallback: errorCallback
      )
    }

    guard let cycle else {
      throw DOFError.invalidFormat(.missingCurrencyDate)
    }

    self.cycle = cycle
    self.obstaclesByID = obstacles
  }

  /// Creates a DOF container by streaming from any async byte sequence.
  ///
  /// Useful for streaming from URLSession.AsyncBytes or other byte sources.
  ///
  /// - Parameters:
  ///   - bytes: An async sequence of bytes to parse.
  ///   - errorCallback: Optional callback for parse errors. Called with (error, lineNumber).
  /// - Throws: DOFError if the file format is invalid.
  public init<S: AsyncSequence>(
    bytes: S,
    errorCallback: ((Error, Int) -> Void)? = nil
  ) async throws where S.Element == UInt8, S: Sendable {
    var obstacles: [String: Obstacle] = [:]
    obstacles.reserveCapacity(Self.estimatedObstacleCount)

    var lineNumber = 0
    var cycle: Cycle?

    for try await line in AsyncBytesLineReader(source: bytes) {
      lineNumber += 1
      try Self.processLine(
        line[...],
        lineNumber: lineNumber,
        cycle: &cycle,
        obstacles: &obstacles,
        errorCallback: errorCallback
      )
    }

    guard let cycle else {
      throw DOFError.invalidFormat(.missingCurrencyDate)
    }

    self.cycle = cycle
    self.obstaclesByID = obstacles
  }

  /// Process a single line from the DOF file.
  private static func processLine(
    _ line: ArraySlice<UInt8>,
    lineNumber: Int,
    cycle: inout Cycle?,
    obstacles: inout [String: Obstacle],
    errorCallback: ((Error, Int) -> Void)?
  ) throws {
    // Line 1: Parse currency date
    if lineNumber == 1 {
      cycle = try DOFByteParser.parseCurrencyDate(line)
      return
    }

    // Lines 2-4: Skip headers
    if lineNumber <= 4 { return }

    // Skip empty lines
    if line.isEmpty { return }

    // Skip separator lines (start with '-')
    if line.first == ASCII.minus { return }

    do {
      let obstacle = try DOFByteParser.parseLine(line, lineNumber: lineNumber)
      obstacles[obstacle.id] = obstacle
    } catch {
      errorCallback?(error, lineNumber)
    }
  }

  // MARK: - Static Factory Methods

  /// Load DOF data from a file path (synchronous).
  ///
  /// - Parameters:
  ///   - filePath: The URL of the DOF file.
  ///   - errorCallback: Optional callback for parse errors.
  /// - Returns: The parsed DOF, or nil if loading failed.
  public static func from(filePath: URL, errorCallback: ((Error, Int) -> Void)? = nil) -> Self? {
    do {
      let data = try Data(contentsOf: filePath)
      return try Self(data: data, errorCallback: errorCallback)
    } catch {
      errorCallback?(error, 0)
      return nil
    }
  }

  /// Load DOF data from raw data.
  ///
  /// - Parameters:
  ///   - data: The DOF file content as Data.
  ///   - errorCallback: Optional callback for parse errors.
  /// - Returns: The parsed DOF, or nil if loading failed.
  public static func from(data: Data, errorCallback: ((Error, Int) -> Void)? = nil) -> Self? {
    do {
      return try Self(data: data, errorCallback: errorCallback)
    } catch {
      errorCallback?(error, 0)
      return nil
    }
  }

  /// Load DOF data from a file URL (async streaming).
  ///
  /// - Parameters:
  ///   - url: The URL of the DOF file.
  ///   - errorCallback: Optional callback for parse errors.
  /// - Returns: The parsed DOF.
  /// - Throws: DOFError if loading or parsing fails.
  public static func from(url: URL, errorCallback: ((Error, Int) -> Void)? = nil) async throws
    -> Self
  {
    try await Self(url: url, errorCallback: errorCallback)
  }

  // MARK: - Lookup Methods

  /// Find an obstacle by its OAS number.
  ///
  /// - Parameter id: The OAS number to look up.
  /// - Returns: The obstacle, or nil if not found.
  public func obstacle(for id: String) -> Obstacle? {
    obstaclesByID[id]
  }

  /// Find all obstacles in a specific state.
  ///
  /// - Parameter state: The state code (e.g., "CA", "TX").
  /// - Returns: Array of obstacles in that state.
  public func obstacles(in state: String) -> [Obstacle] {
    obstaclesByID.values.filter { $0.state == state }
  }
}

// MARK: - Sequence Conformance

extension DOF: Sequence {
  public func makeIterator() -> Dictionary<String, Obstacle>.Values.Iterator {
    obstaclesByID.values.makeIterator()
  }
}

// MARK: - Collection Conformance

extension DOF: Collection {
  public typealias Index = Dictionary<String, Obstacle>.Values.Index

  public var startIndex: Index { obstaclesByID.values.startIndex }
  public var endIndex: Index { obstaclesByID.values.endIndex }

  public func index(after i: Index) -> Index {
    obstaclesByID.values.index(after: i)
  }

  public subscript(position: Index) -> Obstacle {
    obstaclesByID.values[position]
  }
}
