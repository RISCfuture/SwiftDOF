# SwiftDOF

[![Build and Test](https://github.com/RISCfuture/SwiftDOF/actions/workflows/ci.yml/badge.svg)](https://github.com/RISCfuture/SwiftDOF/actions/workflows/ci.yml)
[![Documentation](https://github.com/RISCfuture/SwiftDOF/actions/workflows/doc.yml/badge.svg)](https://riscfuture.github.io/SwiftDOF/)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-blue.svg)](https://swift.org)

A parser for FAA Digital Obstacle File (DOF) data.

## Overview

SwiftDOF parses FAA Digital Obstacle File (DOF) data, which can be downloaded
from <https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/>.

The data is parsed into Codable structs that can be used in your Swift project.

### Design Philosophy

SwiftDOF follows these design principles:

- **Domain-restricted data**: Restrictive enums are favored over open types like
  Strings wherever possible, ensuring type safety and catching errors at compile
  time.

- **Foundation integration**: The library uses `Foundation` types wherever
  possible, such as `Measurement`s instead of raw numeric types for physical
  values.

- **Strict parsing**: The parser throws errors for any malformed or invalid
  data rather than silently accepting it. This ensures data integrity and makes
  debugging easier. All parsing errors are reported via either thrown exceptions
  or the `errorCallback` parameter.

The DOF format is documented at <https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/media/DOF_README_09-03-2019.pdf>.

## Requirements

- Swift 6.2+
- macOS 26+, iOS 26+, watchOS 26+, tvOS 26+, or visionOS 26+

## Installation

Add SwiftDOF to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RISCfuture/SwiftDOF", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftDOF"]
)
```

## Usage

### Loading DOF Data

```swift
import SwiftDOF

// Load from a local file
let dof = try DOF(data: Data(contentsOf: fileURL))

// Or load asynchronously from a URL
let dof = try await DOF(url: fileURL)
```

### Querying Obstacles

```swift
// Get total count
print("Total obstacles: \(dof.count)")

// Look up by OAS number
if let obstacle = dof.obstacle(for: "01-001307") {
    print("\(obstacle.type) at \(obstacle.city), \(obstacle.state ?? "")")
    print("Height: \(obstacle.heightFtAGL) ft AGL")
}

// Filter by state
let texasObstacles = dof.obstacles(in: "TX")

// Iterate over all obstacles
for obstacle in dof {
    // ...
}
```

### Using Measurement Types

```swift
// Heights as Measurement<UnitLength>
let heightAGL = obstacle.heightAGL  // e.g., 500 ft
let heightMeters = heightAGL.converted(to: .meters)

// Coordinates as Measurement<UnitAngle>
let lat = obstacle.latitude
let lon = obstacle.longitude

// Or as CoreLocation coordinate
let coordinate = obstacle.coreLocation
```

### Error Handling

SwiftDOF uses strict parsing and reports all errors. There are two ways to
handle parsing errors:

**1. Catch thrown errors** for fatal issues (invalid format, missing headers):

```swift
do {
    let dof = try DOF(data: fileData)
} catch let error as DOFError {
    switch error {
    case .invalidFormat(let formatError):
        print("Invalid format: \(formatError)")
    case .parseError(let field, let value, let line):
        print("Failed to parse \(field) '\(value)' at line \(line)")
    case .lineTooShort(let expected, let actual, let line):
        print("Line \(line) has \(actual) chars, expected \(expected)")
    case .invalidEncoding:
        print("File contains invalid encoding")
    default:
        print("Error: \(error)")
    }
}
```

**2. Use the error callback** to handle per-line errors while continuing to
parse valid data:

```swift
var parseErrors: [(Error, Int)] = []

let dof = try DOF(data: fileData) { error, lineNumber in
    parseErrors.append((error, lineNumber))
    print("Warning: \(error) at line \(lineNumber)")
}

print("Parsed \(dof.count) obstacles with \(parseErrors.count) errors")
```

The error callback is invoked for each line that fails to parse, allowing you
to collect warnings while still loading the rest of the file. This is useful
for handling DOF files that may contain occasional malformed records.

## Documentation

Online API documentation and tutorials are available at
<https://riscfuture.github.io/SwiftDOF/documentation/swiftdof/>.

DocC documentation is available, including tutorials and API documentation. For
Xcode documentation, you can run

```sh
swift package generate-documentation --target SwiftDOF
```

to generate a docarchive at
`.build/plugins/Swift-DocC/outputs/SwiftDOF.doccarchive`. You can open this
docarchive file in Xcode for browseable API documentation. Or, within Xcode,
open the SwiftDOF package in Xcode and choose **Build Documentation** from the
**Product** menu.

## Testing

SwiftDOF has comprehensive unit tests, which can be run with `swift test`.

### E2E Testing Tool

The `SwiftDOF_E2E` target is a command-line tool for testing DOF parsing:

```sh
# Download and parse current FAA DOF cycle
swift run SwiftDOF_E2E

# Parse a local file
swift run SwiftDOF_E2E -i /path/to/DOF.DAT

# Parse from a URL
swift run SwiftDOF_E2E -i https://aeronav.faa.gov/Obst_Data/DOF_251221.zip

# Output as JSON
swift run SwiftDOF_E2E -f json > obstacles.json
```

Options:
- `-i, --input <path|url>`: Path or URL to DOF file (.dat or .zip). Defaults to current FAA cycle.
- `-f, --format <summary|json>`: Output format. Defaults to summary.
