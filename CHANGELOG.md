# Change Log

## [1.2.0] - 2026-07-06

### Added

- Linux support. `URLSession` is guarded behind `FoundationNetworking`, a
  `String(localized:)` shim covers error strings, and the end-to-end tool's
  download and progress display are adapted for Linux (buffered response and a
  polling progress bar in place of `URLSession.bytes` and KVO).

## [1.1.0] - 2026-06-26

### Changed

- Adopt the Swift 6.2 Approachable Concurrency upcoming features (`NonisolatedNonsendingByDefault` and `InferIsolatedConformances`) across the library, test, and tool targets. The public async API keeps the same signatures and existing source compiles unchanged; the default execution domain of `nonisolated` async entry points (`init(url:)`, `init(bytes:)`, `from(url:)`) now follows the caller's executor.
- Mark the streaming byte line reader's async iterator (`AsyncBytesLineReader.AsyncIterator.next()`) `@concurrent` so large-file and remote-stream parsing continues to run off the caller's executor under the new default.

## [1.0.0] - 2026-01-14

Initial release.
