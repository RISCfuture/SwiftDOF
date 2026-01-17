# ``SwiftDOF``

Parse FAA Digital Obstacle File (DOF) data into Swift types.

## Overview

SwiftDOF provides a high-performance parser for FAA Digital Obstacle File data.
The DOF contains information about obstacles that may pose a hazard to aviation,
including towers, buildings, smokestacks, power lines, and other vertical
structures.

Key features:

- Stream large DOF files with minimal memory usage
- Type-safe enums for obstacle properties
- Integration with Foundation `Measurement` types
- CoreLocation coordinate support
- Full `Codable` conformance
- **Strict parsing** with comprehensive error reporting

### Design Philosophy

SwiftDOF uses **strict parsing** - it throws errors for any malformed or invalid
data rather than silently accepting it. This ensures data integrity and makes
debugging easier. All parsing errors are reported via either thrown exceptions or
the ``DOF/init(data:errorCallback:)`` callback parameter.

## Topics

### Essentials

- <doc:GettingStarted>

### Core Types

- ``DOF``
- ``Obstacle``
- ``Cycle``

### Supporting Types

- ``LightingType``
- ``MarkingType``
- ``ActionCode``
- ``VerificationStatus``
- ``AccuracyCategory``

### Errors

- ``DOFError``
