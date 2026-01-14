# Getting Started with SwiftDOF

Learn how to load and query FAA Digital Obstacle File data.

## Overview

SwiftDOF parses DOF data from the FAA into type-safe Swift structures. DOF data
can be downloaded from <https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/>.

### Loading DOF Data

Load DOF data from a file or URL:

```swift
import SwiftDOF

// From in-memory data
let dof = try DOF(data: fileData)

// From a file URL (async)
let dof = try await DOF(url: fileURL)

// Stream from network
let (bytes, _) = try await URLSession.shared.bytes(from: remoteURL)
let dof = try await DOF(bytes: bytes)
```

### Querying Obstacles

Access obstacles by ID or iterate over all of them:

```swift
// Look up by OAS number
if let obstacle = dof.obstacle(for: "01-001307") {
    print("\(obstacle.type) in \(obstacle.city)")
}

// Filter by state
let texasObstacles = dof.obstacles(in: "TX")

// Iterate over all
for obstacle in dof {
    print(obstacle.oasNumber)
}
```

### Working with Measurements

Obstacle properties integrate with Foundation's `Measurement` types:

```swift
let height = obstacle.heightAGL  // Measurement<UnitLength>
let heightInMeters = height.converted(to: .meters)

let lat = obstacle.latitude      // Measurement<UnitAngle>
let lon = obstacle.longitude

// CoreLocation integration
let coordinate = obstacle.coreLocation  // CLLocationCoordinate2D
```
