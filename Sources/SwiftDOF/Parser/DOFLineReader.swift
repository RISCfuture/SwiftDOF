import Foundation

// MARK: - DOFLineReader

/// Synchronous line reader for DOF data already in memory.
/// Iterates over lines without creating intermediate String or array of all lines.
struct DOFLineReader: Sequence, IteratorProtocol, Sendable {
  /// Pre-allocated capacity for line buffer (DOF lines are ~128 bytes).
  private static let lineBufferCapacity = 256

  private let data: Data
  private var position: Int = 0
  private var lineBuffer: [UInt8] = []

  /// Current read position in bytes, useful for progress tracking.
  var bytesRead: Int { position }

  init(data: Data) {
    self.data = data
    lineBuffer.reserveCapacity(Self.lineBufferCapacity)
  }

  mutating func next() -> ArraySlice<UInt8>? {
    guard position < data.count else { return nil }

    lineBuffer.removeAll(keepingCapacity: true)

    // Scan until LF or end of data
    unsafe data.withUnsafeBytes { buffer in
      let bytes = unsafe buffer.bindMemory(to: UInt8.self)
      while position < bytes.count {
        let byte = unsafe bytes[position]
        position += 1
        if byte == ASCII.LF { return }
        lineBuffer.append(byte)
      }
    }

    // Strip trailing CR if present (handles CRLF)
    if lineBuffer.last == ASCII.CR {
      lineBuffer.removeLast()
    }

    return lineBuffer[...]
  }
}

// MARK: - FileLineReader

/// Line reader that streams DOF data from a file on disk.
/// Reads in chunks so a large file is never held in memory in its entirety.
struct FileLineReader: Sendable {
  /// Default read buffer size (64KB).
  static let defaultBufferSize = 65536

  /// Pre-allocated capacity for line buffer (DOF lines are ~128 bytes).
  private static let lineBufferCapacity = 256

  private let url: URL
  private let bufferSize: Int
  private var handle: FileHandle?
  private var buffer: [UInt8] = []
  private var bufferPosition = 0
  private var lineBuffer: [UInt8] = []
  private var isAtEnd = false

  /// The total size of the file in bytes, if known.
  let fileSize: Int64?

  /// Total bytes read from the file so far.
  private(set) var bytesRead: Int64 = 0

  private var bufferIsExhausted: Bool { bufferPosition >= buffer.count }

  init(url: URL, bufferSize: Int = defaultBufferSize) {
    self.url = url
    self.bufferSize = bufferSize
    self.fileSize = Self.sizeOfFile(at: url)
    lineBuffer.reserveCapacity(Self.lineBufferCapacity)
  }

  /// The size in bytes of the file at `url`, if it can be determined.
  static func sizeOfFile(at url: URL) -> Int64? {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
      return nil
    }
    return attributes[.size] as? Int64
  }

  /// Returns the next line, or `nil` once the file is exhausted.
  mutating func next() throws(DOFError) -> [UInt8]? {
    guard !isAtEnd else { return nil }

    let handle = try openedHandle()
    lineBuffer.removeAll(keepingCapacity: true)

    while true {
      if bufferIsExhausted {
        guard let chunk = try readChunk(from: handle), !chunk.isEmpty else {
          isAtEnd = true
          return lineBuffer.isEmpty ? nil : lineBuffer
        }
        bytesRead += Int64(chunk.count)
        buffer = Array(chunk)
        bufferPosition = 0
      }

      let byte = buffer[bufferPosition]
      bufferPosition += 1

      if byte == ASCII.LF {
        // Strip trailing CR if present (handles CRLF)
        if lineBuffer.last == ASCII.CR {
          lineBuffer.removeLast()
        }
        return lineBuffer
      }
      lineBuffer.append(byte)
    }
  }

  private mutating func openedHandle() throws(DOFError) -> FileHandle {
    if let handle { return handle }
    guard let opened = try? FileHandle(forReadingFrom: url) else {
      throw DOFError.fileNotFound(url)
    }
    handle = opened
    return opened
  }

  private func readChunk(from handle: FileHandle) throws(DOFError) -> Data? {
    do {
      return try handle.read(upToCount: bufferSize)
    } catch {
      throw DOFError.streamError(error)
    }
  }
}

// MARK: - AsyncDOFLineReader

/// Async façade over ``FileLineReader`` for `for await` iteration of a DOF file.
struct AsyncDOFLineReader: AsyncSequence, Sendable {
  typealias Element = [UInt8]
  typealias Failure = DOFError

  private let url: URL
  private let bufferSize: Int

  /// The total size of the file in bytes, if known.
  let fileSize: Int64?

  init(url: URL, bufferSize: Int = FileLineReader.defaultBufferSize) {
    self.url = url
    self.bufferSize = bufferSize
    self.fileSize = FileLineReader.sizeOfFile(at: url)
  }

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(reader: FileLineReader(url: url, bufferSize: bufferSize))
  }

  struct AsyncIterator: AsyncIteratorProtocol {
    private var reader: FileLineReader

    init(reader: FileLineReader) {
      self.reader = reader
    }

    mutating func next() throws(DOFError) -> [UInt8]? {
      try reader.next()
    }
  }
}

// MARK: - AsyncBytesLineReader

/// Generic async line reader that accepts any AsyncSequence of bytes.
/// Useful for streaming from URLSession.AsyncBytes or other byte sources.
struct AsyncBytesLineReader<Source: AsyncSequence>: AsyncSequence, Sendable
where Source.Element == UInt8, Source: Sendable {
  typealias Element = [UInt8]
  typealias Failure = Source.Failure

  /// Pre-allocated capacity for line buffer (DOF lines are ~128 bytes).
  private static var lineBufferCapacity: Int { 256 }

  private let source: Source

  init(source: Source) {
    self.source = source
  }

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(iterator: source.makeAsyncIterator())
  }

  struct AsyncIterator: AsyncIteratorProtocol {
    private var iterator: Source.AsyncIterator
    private var lineBuffer: [UInt8] = []

    init(iterator: Source.AsyncIterator) {
      self.iterator = iterator
      lineBuffer.reserveCapacity(lineBufferCapacity)
    }

    @concurrent
    mutating func next() async throws(Source.Failure) -> [UInt8]? {
      lineBuffer.removeAll(keepingCapacity: true)

      while let byte = try await iterator.next(isolation: nil) {
        if byte == ASCII.LF {
          // Strip trailing CR if present (handles CRLF)
          if lineBuffer.last == ASCII.CR {
            lineBuffer.removeLast()
          }
          return lineBuffer
        }
        lineBuffer.append(byte)
      }

      // Return remaining content as final line
      return lineBuffer.isEmpty ? nil : lineBuffer
    }
  }
}
