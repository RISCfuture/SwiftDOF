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

  init(data: Data) {
    self.data = data
    lineBuffer.reserveCapacity(Self.lineBufferCapacity)
  }

  mutating func next() -> ArraySlice<UInt8>? {
    guard position < data.count else { return nil }

    lineBuffer.removeAll(keepingCapacity: true)

    // Scan until LF or end of data
    data.withUnsafeBytes { buffer in
      let bytes = buffer.bindMemory(to: UInt8.self)
      while position < bytes.count {
        let byte = bytes[position]
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

// MARK: - AsyncDOFLineReader

/// Async line reader for streaming DOF data from a file URL.
/// Reads in chunks to minimize memory usage for large files.
struct AsyncDOFLineReader: AsyncSequence, Sendable {
  typealias Element = [UInt8]

  /// Default read buffer size (64KB).
  static let defaultBufferSize = 65536

  /// Pre-allocated capacity for line buffer (DOF lines are ~128 bytes).
  private static let lineBufferCapacity = 256

  private let url: URL
  private let bufferSize: Int

  init(url: URL, bufferSize: Int = defaultBufferSize) {
    self.url = url
    self.bufferSize = bufferSize
  }

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(url: url, bufferSize: bufferSize)
  }

  struct AsyncIterator: AsyncIteratorProtocol {
    private let url: URL
    private let bufferSize: Int
    private var handle: FileHandle?
    private var buffer: [UInt8] = []
    private var bufferPos: Int = 0
    private var lineBuffer: [UInt8] = []
    private var isEOF = false

    init(url: URL, bufferSize: Int) {
      self.url = url
      self.bufferSize = bufferSize
      self.lineBuffer.reserveCapacity(lineBufferCapacity)
    }

    mutating func next() throws -> [UInt8]? {
      guard !isEOF else { return nil }

      // Lazily open file handle on first call
      if handle == nil {
        handle = try FileHandle(forReadingFrom: url)
      }
      guard let handle else { preconditionFailure("handle was nil") }

      lineBuffer.removeAll(keepingCapacity: true)

      while true {
        // Refill buffer if exhausted
        if bufferPos >= buffer.count {
          guard let chunk = try handle.read(upToCount: bufferSize),
            !chunk.isEmpty
          else {
            isEOF = true
            // Return any remaining content as final line
            return lineBuffer.isEmpty ? nil : lineBuffer
          }
          buffer = Array(chunk)
          bufferPos = 0
        }

        let byte = buffer[bufferPos]
        bufferPos += 1

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
  }
}

// MARK: - AsyncBytesLineReader

/// Generic async line reader that accepts any AsyncSequence of bytes.
/// Useful for streaming from URLSession.AsyncBytes or other byte sources.
struct AsyncBytesLineReader<Source: AsyncSequence>: AsyncSequence, Sendable
where Source.Element == UInt8, Source: Sendable {
  typealias Element = [UInt8]

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

    mutating func next() async throws -> [UInt8]? {
      lineBuffer.removeAll(keepingCapacity: true)

      while let byte = try await iterator.next() {
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
