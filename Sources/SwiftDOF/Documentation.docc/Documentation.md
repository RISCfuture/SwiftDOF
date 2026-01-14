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
