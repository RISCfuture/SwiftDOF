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

- Adopt typed throws across the parsing surface: `DOF.init(data:)`, `DOF.init(url:)`, the `DOF.from(…)` factories, and `DOFByteParser` now declare `throws(DOFError)`, and the DOF file line reader's `AsyncIteratorProtocol.Failure` is `DOFError`. `AsyncBytesLineReader` propagates its source sequence's own `Failure` type.
- `DOF.from(filePath:)` streams the file in chunks instead of reading it into memory in its entirety. A file that cannot be opened now throws `DOFError.fileNotFound` rather than a Foundation file-read error.
- Match the header's "CURRENCY DATE = " marker against an `InlineArray<16, UInt8>`, removing a heap allocation from currency date parsing.

### Fixed

- `Obstacle.marking` reads the mark indicator from column 102 rather than column
  100, which holds the vertical accuracy code. Because the old `MarkingType`
  cases `A`-`I` coincided exactly with the vertical accuracy code set, every
  record in every cycle parsed without error and reported the wrong marking —
  an obstacle with a ±50 foot height tolerance (`D`) read as `.paintAndFlags`.
  The vertical accuracy column is now exposed as `Obstacle.verticalAccuracy`.
- `Cycle.previous`, `Cycle.next`, and the cycle datum date no longer force-unwrap optionals.

## [1.3.0] - 2026-09-14

### Changed

- Lower the platform floor from macOS 26, iOS 26, watchOS 26, tvOS 26, and
  visionOS 26 to macOS 15, iOS 18, watchOS 11, tvOS 18, and visionOS 2. Nothing
  in the package used a macOS 26 API; the floor sits at 15 rather than lower
  because `DateComponents.dayOfYear`, which reads the DOF's YYYYDDD Julian date
  field, is available from macOS 15 onward.
- Require swift-argument-parser 1.8.2 and swift-docc-plugin 1.5.0 as the minimum
  versions of those dependencies.

### Fixed

- The six symbol links in the DocC catalog resolve again. They named the
  initializers that the progress-handling API replaced, so the rendered
  documentation shipped with dead links.

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
