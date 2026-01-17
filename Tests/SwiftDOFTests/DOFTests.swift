import Testing
import Foundation
@testable import SwiftDOF

struct DOFTests {

  let sampleDOFContent = """
    CURRENCY DATE = 12/21/25
                                       LATITUDE     LONGITUDE     OBSTACLE             AGL   AMSL \
    LT ACC MAR FAA          ACTION
    OAS#      V CO ST CITY             DEG MIN SEC  DEG MIN SEC   TYPE                 HT    \
    HT     H V IND STUDY           JDATE
    -------------------------------------------------------------------------------------------------------------------------------
    01-001307 O US AL DAUPHIN ISLAND   30 10 45.00N 088 04 39.00W RIG                1 00236 00236 \
    R 5 D M 1990ASO01578OE C 2014138
    01-001459 O US AL DAUPHIN ISLAND   30 11 20.00N 088 07 15.00W RIG                1 00240 00241 \
    R 5 D M 1992ASO02229OE C 2014138
    01-001472 O US AL FORT MORGAN      30 11 20.00N 087 57 10.00W STACK              1 00193 00193 \
    R 5 D M 1992ASO02230OE C 2014138
    """

  var sampleDOFData: Data {
    sampleDOFContent.data(using: .utf8)!
  }

  @Test("Parse DOF data")
  func testParseDOFData() throws {
    let dof = try DOF(data: sampleDOFData)

    #expect(dof.count == 3)
    #expect(dof.cycle.year == 2025)
    #expect(dof.cycle.month == 12)
    #expect(dof.cycle.day == 21)
  }

  @Test("Lookup obstacle by ID")
  func testLookupByID() throws {
    let dof = try DOF(data: sampleDOFData)

    let obstacle = try #require(dof.obstacle(for: "01-001307"))
    #expect(obstacle.oasNumber == "01-001307")
    #expect(obstacle.type == "RIG")
  }

  @Test("Lookup non-existent obstacle returns nil")
  func testLookupNonExistent() throws {
    let dof = try DOF(data: sampleDOFData)

    let obstacle = dof.obstacle(for: "99-999999")
    #expect(obstacle == nil)
  }

  @Test("All property returns all obstacles")
  func testAllProperty() throws {
    let dof = try DOF(data: sampleDOFData)

    let all = dof.all
    #expect(all.count == 3)
  }

  @Test("Count property")
  func testCountProperty() throws {
    let dof = try DOF(data: sampleDOFData)
    #expect(dof.count == 3)
  }

  @Test("Sequence conformance - iteration")
  func testSequenceIteration() throws {
    let dof = try DOF(data: sampleDOFData)

    var count = 0
    for _ in dof {
      count += 1
    }
    #expect(count == 3)
  }

  @Test("Collection conformance")
  func testCollectionConformance() throws {
    let dof = try DOF(data: sampleDOFData)

    #expect(!dof.isEmpty)
    #expect(dof.startIndex != dof.endIndex)
  }

  @Test("Filter obstacles by state")
  func testFilterByState() throws {
    let dof = try DOF(data: sampleDOFData)

    let alObstacles = dof.obstacles(in: "AL")
    #expect(alObstacles.count == 3)

    let caObstacles = dof.obstacles(in: "CA")
    #expect(caObstacles.isEmpty)
  }

  @Test("DOF is Codable")
  func testCodable() throws {
    let dof = try DOF(data: sampleDOFData)

    let encoder = JSONEncoder()
    let data = try encoder.encode(dof)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(DOF.self, from: data)

    #expect(decoded.count == dof.count)
    #expect(decoded.cycle == dof.cycle)
  }

  @Test("Parse currency date")
  func testParseCurrencyDate() throws {
    let bytes: [UInt8] = Array("  CURRENCY DATE = 12/21/25".utf8)
    let cycle = try DOFByteParser.parseCurrencyDate(bytes[...])

    #expect(cycle.year == 2025)
    #expect(cycle.month == 12)
    #expect(cycle.day == 21)
  }

  @Test("Error callback is invoked for malformed lines")
  func testErrorCallback() throws {
    let contentWithError = """
      CURRENCY DATE = 12/21/25
                                         LATITUDE     LONGITUDE     OBSTACLE             AGL   \
      AMSL LT ACC MAR FAA          ACTION
      OAS#      V CO ST CITY             DEG MIN SEC  DEG MIN SEC   TYPE                 HT    \
      HT     H V IND STUDY           JDATE
      -------------------------------------------------------------------------------------------------------------------------------
      01-001307 O US AL DAUPHIN ISLAND   30 10 45.00N 088 04 39.00W RIG                1 00236 \
      00236 R 5 D M 1990ASO01578OE C 2014138
      INVALID LINE TOO SHORT
      01-001459 O US AL DAUPHIN ISLAND   30 11 20.00N 088 07 15.00W RIG                1 00240 \
      00241 R 5 D M 1992ASO02229OE C 2014138
      """

    var errorCount = 0
    let dof = try DOF(data: contentWithError.data(using: .utf8)!) { _, _ in
      errorCount += 1
    }

    #expect(dof.count == 2)  // Only 2 valid lines
    #expect(errorCount == 1)  // 1 error for the invalid line
  }

  @Test("Empty data throws error")
  func testEmptyData() {
    #expect(throws: DOFError.self) {
      try DOF(data: Data())
    }
  }

  @Test("Data with only header produces empty DOF")
  func testOnlyHeader() throws {
    let headerOnly = """
      CURRENCY DATE = 12/21/25
      HEADER
      FIELDS
      """

    let dof = try DOF(data: headerOnly.data(using: .utf8)!)
    #expect(dof.isEmpty)
    #expect(dof.cycle.year == 2025)
  }

  @Test("From data factory method")
  func testFromData() throws {
    let dof = try DOF.from(data: sampleDOFData)
    #expect(dof.count == 3)
  }

  @Test("From data with error callback")
  func testFromDataWithErrorCallback() throws {
    var errorCalled = false

    let dof = try DOF.from(data: sampleDOFData) { _, _ in
      errorCalled = true
    }

    #expect(dof.count == 3)
    #expect(!errorCalled)  // No errors in valid content
  }
}
