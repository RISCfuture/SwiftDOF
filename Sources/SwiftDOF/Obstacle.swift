import CoreLocation
import Foundation

/// Represents a single obstacle from the FAA Digital Obstacle File.
///
/// Each obstacle record contains information about a man-made or natural structure
/// that may pose a hazard to aviation. This includes towers, buildings, smokestacks,
/// power lines, and other vertical structures.
public struct Obstacle: Sendable, Codable {

  /// Calendar used for date conversions.
  private static var calendar: Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = .gmt
    return cal
  }

  // MARK: - Identification

  /// The Obstacle Assessment Study (OAS) number.
  ///
  /// This is the unique identifier for the obstacle in the format "NN-NNNNNN"
  /// where the first two digits represent the state FIPS code.
  public let oasNumber: String

  /// The verification status of the obstacle data.
  public let verificationStatus: VerificationStatus

  // MARK: - Location

  /// The country code (typically "US" for United States).
  public let country: String

  /// The state or territory code (e.g., "AL", "CA", "PR").
  public let state: String?

  /// The city or location name.
  public let city: String

  /// The latitude in decimal degrees (positive for North).
  public let latitudeDeg: Double

  /// The longitude in decimal degrees (negative for West).
  public let longitudeDeg: Double

  // MARK: - Physical Characteristics

  /// The type of obstacle (e.g., "TOWER", "BLDG", "ANTENNA").
  public let type: String

  /// The number of obstacles at this location.
  public let quantity: UInt8

  /// The height above ground level in feet.
  public let heightFtAGL: Int

  /// The height above mean sea level in feet (can be negative for locations below sea level).
  public let heightFtMSL: Int

  // MARK: - Marking and Lighting

  /// The type of lighting installed on the obstacle.
  public let lighting: LightingType

  /// The horizontal accuracy category.
  public let horizontalAccuracy: AccuracyCategory

  /// The marking type (paint, flags, etc.).
  public let marking: MarkingType

  // MARK: - Administrative

  /// The OE (Obstruction Evaluation) study reference number.
  public let studyNumber: String

  /// The action code indicating record status.
  public let action: ActionCode

  /// The date components of the last update (year and dayOfYear).
  public let lastUpdatedComponents: DateComponents

  /// The date of the last update.
  public var lastUpdatedDate: Date? {
    Self.calendar.date(from: lastUpdatedComponents)
  }

  // MARK: - Initialization

  /// Creates a new obstacle with all required fields.
  public init(
    oasNumber: String,
    verificationStatus: VerificationStatus,
    country: String,
    state: String?,
    city: String,
    latitudeDeg: Double,
    longitudeDeg: Double,
    type: String,
    quantity: UInt8,
    heightFtAGL: Int,
    heightFtMSL: Int,
    lighting: LightingType,
    horizontalAccuracy: AccuracyCategory,
    marking: MarkingType,
    studyNumber: String,
    action: ActionCode,
    lastUpdatedComponents: DateComponents
  ) {
    self.oasNumber = oasNumber
    self.verificationStatus = verificationStatus
    self.country = country
    self.state = state
    self.city = city
    self.latitudeDeg = latitudeDeg
    self.longitudeDeg = longitudeDeg
    self.type = type
    self.quantity = quantity
    self.heightFtAGL = heightFtAGL
    self.heightFtMSL = heightFtMSL
    self.lighting = lighting
    self.horizontalAccuracy = horizontalAccuracy
    self.marking = marking
    self.studyNumber = studyNumber
    self.action = action
    self.lastUpdatedComponents = lastUpdatedComponents
  }
}

extension Obstacle: Identifiable {
  /// The unique identifier for this obstacle (the OAS number).
  public var id: String { oasNumber }
}

extension Obstacle: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(oasNumber)
  }
}

extension Obstacle: Equatable {
  public static func == (lhs: Obstacle, rhs: Obstacle) -> Bool {
    lhs.oasNumber == rhs.oasNumber
  }
}

// MARK: - Measurement Extensions

public extension Obstacle {
  /// The latitude as a `Measurement<UnitAngle>` in degrees.
  var latitude: Measurement<UnitAngle> {
    .init(value: latitudeDeg, unit: .degrees)
  }

  /// The longitude as a `Measurement<UnitAngle>` in degrees.
  var longitude: Measurement<UnitAngle> {
    .init(value: longitudeDeg, unit: .degrees)
  }

  /// The height above ground level as a `Measurement<UnitLength>` in feet.
  var heightAGL: Measurement<UnitLength> {
    .init(value: Double(heightFtAGL), unit: .feet)
  }

  /// The height above mean sea level as a `Measurement<UnitLength>` in feet.
  var heightMSL: Measurement<UnitLength> {
    .init(value: Double(heightFtMSL), unit: .feet)
  }
}

// MARK: - CoreLocation Extensions

public extension Obstacle {
  /// The obstacle location as a CoreLocation coordinate.
  var coreLocation: CLLocationCoordinate2D {
    .init(latitude: latitudeDeg, longitude: longitudeDeg)
  }
}
