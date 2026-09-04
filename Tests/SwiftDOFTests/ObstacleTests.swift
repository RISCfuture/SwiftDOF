import Testing
import Foundation

#if canImport(CoreLocation)
  import CoreLocation
#endif

@testable import SwiftDOF

struct ObstacleTests {

  // Sample DOF record line as bytes
  let sampleLineBytes: [UInt8] = Array(
    "01-001307 O US AL DAUPHIN ISLAND   30 10 45.00N 088 04 39.00W RIG                1 00236 00236 R 5 D M 1990ASO01578OE C 2014138 "
      .utf8
  )

  @Test
  func `parses every field of a valid obstacle line`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    #expect(obstacle.oasNumber == "01-001307")
    #expect(obstacle.verificationStatus == .operational)
    #expect(obstacle.country == "US")
    #expect(obstacle.state == "AL")
    #expect(obstacle.city == "DAUPHIN ISLAND")
    #expect(obstacle.type == "RIG")
    #expect(obstacle.quantity == 1)
    #expect(obstacle.heightFtAGL == 236)
    #expect(obstacle.heightFtMSL == 236)
    #expect(obstacle.lighting == .red)
    #expect(obstacle.horizontalAccuracy == .category5)
    #expect(obstacle.marking == .paintAndFlags)
    #expect(obstacle.action == .changed)
    #expect(obstacle.lastUpdatedComponents.year == 2014)
    #expect(obstacle.lastUpdatedComponents.dayOfYear == 138)
  }

  @Test
  func `converts a northern latitude to positive degrees`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    // 30 10 45.00N = 30 + 10/60 + 45/3600 = 30.179166...
    let expectedLat = 30.0 + 10.0 / 60.0 + 45.0 / 3600.0
    #expect(abs(obstacle.latitudeDeg - expectedLat) < 0.0001)
    #expect(obstacle.latitudeDeg > 0)  // North is positive
  }

  @Test
  func `converts a western longitude to negative degrees`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    // 088 04 39.00W = -(88 + 4/60 + 39/3600) = -88.0775
    let expectedLon = -(88.0 + 4.0 / 60.0 + 39.0 / 3600.0)
    #expect(abs(obstacle.longitudeDeg - expectedLon) < 0.0001)
    #expect(obstacle.longitudeDeg < 0)  // West is negative
  }

  @Test
  func `identifies an obstacle by its OAS number`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    #expect(obstacle.id == "01-001307")
  }

  @Test
  func `hashes two identical obstacles into one set element`() throws {
    let obstacle1 = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let obstacle2 = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    var set: Set<Obstacle> = []
    set.insert(obstacle1)
    set.insert(obstacle2)

    #expect(set.count == 1)
  }

  @Test
  func `considers two obstacles parsed from the same line equal`() throws {
    let obstacle1 = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let obstacle2 = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    #expect(obstacle1 == obstacle2)
  }

  @Test
  func `parses the obstacle type of a tower and a building`() throws {
    let towerBytes: [UInt8] = Array(
      "01-001173 O US AL DAUPHIN ISLAND   30 15 01.00N 088 04 45.00W TOWER              1 00201 00205 R 5 D M 1988ASO02440OE C 2014138 "
        .utf8
    )
    let tower = try DOFByteParser.parseLine(towerBytes[...], lineNumber: 1)
    #expect(tower.type == "TOWER")

    let bldgBytes: [UInt8] = Array(
      "01-002558 O US AL GULF SHORES      30 13 49.00N 087 52 30.00W BLDG               1 00223 00242 R 5 D N 1999ASO03256OE C 2004005 "
        .utf8
    )
    let bldg = try DOFByteParser.parseLine(bldgBytes[...], lineNumber: 1)
    #expect(bldg.type == "BLDG")
  }

  @Test
  func `parses the under-review verification status`() throws {
    let bytes: [UInt8] = Array(
      "01-061332 U US AL GULF SHORES      30 14 43.32N 087 42 12.20W BLDG               1 00059 00067 N 4 D N 2018ASO25793OE A 2020230 "
        .utf8
    )
    let obstacle = try DOFByteParser.parseLine(bytes[...], lineNumber: 1)
    #expect(obstacle.verificationStatus == .underReview)
  }

  @Test
  func `parses the active action code`() throws {
    let bytes: [UInt8] = Array(
      "01-061332 U US AL GULF SHORES      30 14 43.32N 087 42 12.20W BLDG               1 00059 00067 N 4 D N 2018ASO25793OE A 2020230 "
        .utf8
    )
    let obstacle = try DOFByteParser.parseLine(bytes[...], lineNumber: 1)
    #expect(obstacle.action == .active)
  }

  #if canImport(CoreLocation)
    @Test
    func `exposes the obstacle position as a CoreLocation coordinate`() throws {
      let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
      let coordinate = obstacle.coreLocation

      #expect(coordinate.latitude == obstacle.latitudeDeg)
      #expect(coordinate.longitude == obstacle.longitudeDeg)
    }
  #endif

  @Test
  func `exposes the latitude as a measurement in degrees`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let latitude = obstacle.latitude

    #expect(latitude.unit == .degrees)
    #expect(latitude.value == obstacle.latitudeDeg)
  }

  @Test
  func `exposes the longitude as a measurement in degrees`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let longitude = obstacle.longitude

    #expect(longitude.unit == .degrees)
    #expect(longitude.value == obstacle.longitudeDeg)
  }

  @Test
  func `exposes the height AGL as a measurement in feet`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let height = obstacle.heightAGL

    #expect(height.unit == .feet)
    #expect(height.value == Double(obstacle.heightFtAGL))
  }

  @Test
  func `exposes the height MSL as a measurement in feet`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)
    let height = obstacle.heightMSL

    #expect(height.unit == .feet)
    #expect(height.value == Double(obstacle.heightFtMSL))
  }

  @Test
  func `parses every lighting type from its raw value`() {
    for type in LightingType.allCases {
      #expect(LightingType(rawValue: type.rawValue) == type)
    }
  }

  @Test
  func `maps accuracy categories to their tolerances in feet`() {
    #expect(AccuracyCategory.category1.accuracy == Measurement(value: 20, unit: .feet))
    #expect(AccuracyCategory.category5.accuracy == Measurement(value: 500, unit: .feet))
    #expect(AccuracyCategory.category9.accuracy == nil)  // Unknown
    #expect(AccuracyCategory.survey.accuracy == Measurement(value: 3, unit: .feet))
  }

  @Test
  func `throws when the line is too short`() {
    let shortBytes: [UInt8] = Array("01-001307 O US AL".utf8)

    #expect(throws: DOFError.self) {
      try DOFByteParser.parseLine(shortBytes[...], lineNumber: 1)
    }
  }

  @Test
  func `round-trips an obstacle through JSON`() throws {
    let obstacle = try DOFByteParser.parseLine(sampleLineBytes[...], lineNumber: 1)

    let encoder = JSONEncoder()
    let data = try encoder.encode(obstacle)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Obstacle.self, from: data)

    #expect(decoded == obstacle)
    #expect(decoded.oasNumber == obstacle.oasNumber)
    #expect(decoded.latitudeDeg == obstacle.latitudeDeg)
    #expect(decoded.longitudeDeg == obstacle.longitudeDeg)
  }
}
