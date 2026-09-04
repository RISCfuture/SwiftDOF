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

  @Test
  func `parses obstacles and the currency date from DOF data`() throws {
    let dof = try DOF(data: sampleDOFData)

    #expect(dof.count == 3)
    #expect(dof.cycle.year == 2025)
    #expect(dof.cycle.month == 12)
    #expect(dof.cycle.day == 21)
  }

  @Test
  func `looks up an obstacle by its OAS number`() throws {
    let dof = try DOF(data: sampleDOFData)

    let obstacle = try #require(dof.obstacle(for: "01-001307"))
    #expect(obstacle.oasNumber == "01-001307")
    #expect(obstacle.type == "RIG")
  }

  @Test
  func `returns nil for an unknown OAS number`() throws {
    let dof = try DOF(data: sampleDOFData)

    let obstacle = dof.obstacle(for: "99-999999")
    #expect(obstacle == nil)
  }

  @Test
  func `returns every obstacle from all`() throws {
    let dof = try DOF(data: sampleDOFData)

    let all = dof.all
    #expect(all.count == 3)
  }

  @Test
  func `counts the parsed obstacles`() throws {
    let dof = try DOF(data: sampleDOFData)
    #expect(dof.count == 3)
  }

  @Test
  func `iterates over every obstacle as a sequence`() throws {
    let dof = try DOF(data: sampleDOFData)

    var count = 0
    for _ in dof {
      count += 1
    }
    #expect(count == 3)
  }

  @Test
  func `exposes obstacles as a non-empty collection`() throws {
    let dof = try DOF(data: sampleDOFData)

    #expect(!dof.isEmpty)
    #expect(dof.startIndex != dof.endIndex)
  }

  @Test
  func `filters obstacles by state`() throws {
    let dof = try DOF(data: sampleDOFData)

    let alObstacles = dof.obstacles(in: "AL")
    #expect(alObstacles.count == 3)

    let caObstacles = dof.obstacles(in: "CA")
    #expect(caObstacles.isEmpty)
  }

  @Test
  func `round-trips a DOF through JSON`() throws {
    let dof = try DOF(data: sampleDOFData)

    let encoder = JSONEncoder()
    let data = try encoder.encode(dof)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(DOF.self, from: data)

    #expect(decoded.count == dof.count)
    #expect(decoded.cycle == dof.cycle)
  }

  @Test
  func `parses the currency date header into a cycle`() throws {
    let bytes: [UInt8] = Array("  CURRENCY DATE = 12/21/25".utf8)
    let cycle = try DOFByteParser.parseCurrencyDate(bytes[...])

    #expect(cycle.year == 2025)
    #expect(cycle.month == 12)
    #expect(cycle.day == 21)
  }

  @Test
  func `invokes the error callback for a malformed line and skips it`() throws {
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
    let dof = try DOF(
      data: contentWithError.data(using: .utf8)!,
      errorCallback: { _, _ in
        errorCount += 1
      }
    )

    #expect(dof.count == 2)  // Only 2 valid lines
    #expect(errorCount == 1)  // 1 error for the invalid line
  }

  @Test
  func `throws when the data is empty`() {
    #expect(throws: DOFError.self) {
      try DOF(data: Data())
    }
  }

  @Test
  func `parses a header-only file into an empty DOF`() throws {
    let headerOnly = """
      CURRENCY DATE = 12/21/25
      HEADER
      FIELDS
      """

    let dof = try DOF(data: headerOnly.data(using: .utf8)!)
    #expect(dof.isEmpty)
    #expect(dof.cycle.year == 2025)
  }

  @Test
  func `parses obstacles through the from(data:) factory`() throws {
    let dof = try DOF.from(data: sampleDOFData)
    #expect(dof.count == 3)
  }

  @Test
  func `leaves the error callback uncalled for valid data`() throws {
    var errorCalled = false

    let dof = try DOF.from(
      data: sampleDOFData,
      errorCallback: { _, _ in
        errorCalled = true
      }
    )

    #expect(dof.count == 3)
    #expect(!errorCalled)  // No errors in valid content
  }
}
