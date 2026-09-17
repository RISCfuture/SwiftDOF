# Change Log

## [Unreleased]

### Added

- `Obstacle.verticalAccuracy`, the accuracy category of an obstacle's reported
  height, read from column 100 of the DOF record.

### Changed

- **Breaking.** `AccuracyCategory` is replaced by two enums that each carry only
  the codes the FAA defines for their column: `HorizontalAccuracy` (`1`-`9`) and
  `VerticalAccuracy` (`A`-`I`). `Obstacle.horizontalAccuracy` is now a
  `HorizontalAccuracy`. The `.survey` case (±3 feet) becomes
  `VerticalAccuracy.codeA`, the vertical column it belongs to. Cases are named
  for the code the FAA publishes — `.code1`, `.codeA` — rather than a "category"
  the criteria never use, and the tolerance each one guarantees is now spelled
  `tolerance` rather than `accuracy`.
- **Breaking.** `MarkingType`'s cases are the mark indicator codes the DOF
  actually uses — `orangeOrOrangeWhitePaint` (`P`), `whitePaintOnly` (`W`),
  `marked` (`M`), `flagMarker` (`F`), `sphericalMarker` (`S`), `none` (`N`), and
  `unknown` (`U`) — in place of the `A`-`I` cases, which described a code set
  that appears nowhere in the DOF. A blank column parses as `.unknown`.

### Fixed

- `Obstacle.marking` reads the mark indicator from column 102 rather than column
  100, which holds the vertical accuracy code. Because the old `MarkingType`
  cases `A`-`I` coincided exactly with the vertical accuracy code set, every
  record in every cycle parsed without error and reported the wrong marking —
  an obstacle with a ±50 foot height tolerance (`D`) read as `.paintAndFlags`.
  The vertical accuracy column is now exposed as `Obstacle.verticalAccuracy`.

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
