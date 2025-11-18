import XCTest
@testable import HabitTracker

final class MeasurementDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let measurement = TestFixtures.makeMeasurement(
            value: 500.0,
            unit: .ml
        )

        // When
        let dto = MeasurementDTO(from: measurement)

        // Then
        XCTAssertEqual(dto.id, measurement.id)
        XCTAssertEqual(dto.userId, measurement.userId)
        XCTAssertEqual(dto.goalId, measurement.goalId)
        XCTAssertEqual(dto.occurrenceId, measurement.occurrenceId)
        XCTAssertEqual(dto.value, 500.0)
        XCTAssertEqual(dto.unit, "ml")
    }

    func testInitFromDomainWithDifferentUnits() {
        // Given
        let measurements = [
            TestFixtures.makeMeasurement(id: UUID(), value: 2.5, unit: .l),
            TestFixtures.makeMeasurement(id: UUID(), value: 70.0, unit: .kg),
            TestFixtures.makeMeasurement(id: UUID(), value: 30.0, unit: .minutes),
            TestFixtures.makeMeasurement(id: UUID(), value: 1.5, unit: .hours),
            TestFixtures.makeMeasurement(id: UUID(), value: 5.0, unit: .count)
        ]

        // When & Then
        XCTAssertEqual(MeasurementDTO(from: measurements[0]).unit, "l")
        XCTAssertEqual(MeasurementDTO(from: measurements[1]).unit, "kg")
        XCTAssertEqual(MeasurementDTO(from: measurements[2]).unit, "minutes")
        XCTAssertEqual(MeasurementDTO(from: measurements[3]).unit, "hours")
        XCTAssertEqual(MeasurementDTO(from: measurements[4]).unit, "count")
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = TestFixtures.makeMeasurementDTO(
            value: 750.0,
            unit: "oz"
        )

        // When
        let measurement = dto.toDomain

        // Then
        XCTAssertEqual(measurement.id, dto.id)
        XCTAssertEqual(measurement.userId, dto.userId)
        XCTAssertEqual(measurement.goalId, dto.goalId)
        XCTAssertEqual(measurement.occurrenceId, dto.occurrenceId)
        XCTAssertEqual(measurement.value, 750.0)
        XCTAssertEqual(measurement.unit, .oz)
    }

    func testToDomainWithUnknownUnit() {
        // Given
        var dto = TestFixtures.makeMeasurementDTO()
        // Manually create DTO with invalid unit using mirror
        let dto2 = MeasurementDTO(
            id: dto.id,
            userId: dto.userId,
            goalId: dto.goalId,
            occurrenceId: dto.occurrenceId,
            value: dto.value,
            unit: "invalid_unit",
            recordedAt: dto.recordedAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )

        // When
        let measurement = dto2.toDomain

        // Then - Should fall back to .count
        XCTAssertEqual(measurement.unit, .count)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalMeasurement = TestFixtures.makeMeasurement(
            value: 1200.0,
            unit: .ml
        )

        // When
        let dto = MeasurementDTO(from: originalMeasurement)
        let convertedMeasurement = dto.toDomain

        // Then
        XCTAssertEqual(convertedMeasurement.id, originalMeasurement.id)
        XCTAssertEqual(convertedMeasurement.userId, originalMeasurement.userId)
        XCTAssertEqual(convertedMeasurement.goalId, originalMeasurement.goalId)
        XCTAssertEqual(convertedMeasurement.occurrenceId, originalMeasurement.occurrenceId)
        XCTAssertEqual(convertedMeasurement.value, originalMeasurement.value)
        XCTAssertEqual(convertedMeasurement.unit, originalMeasurement.unit)
    }

    // MARK: - Codable Tests

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "\(TestFixtures.measurementId.uuidString)",
            "user_id": "\(TestFixtures.userId.uuidString)",
            "goal_id": "\(TestFixtures.goalId.uuidString)",
            "occurrence_id": null,
            "value": 500.0,
            "unit": "ml",
            "recorded_at": "2023-11-14T12:00:00Z",
            "created_at": "2023-11-14T12:00:00Z",
            "updated_at": "2023-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let dto = try decoder.decode(MeasurementDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.id, TestFixtures.measurementId)
        XCTAssertEqual(dto.value, 500.0)
        XCTAssertEqual(dto.unit, "ml")
        XCTAssertNil(dto.occurrenceId)
    }

    func testCodableEncodingWithOccurrenceId() throws {
        // Given
        let occurrenceId = UUID()
        let measurement = TestFixtures.makeMeasurement(
            occurrenceId: occurrenceId,
            value: 250.0,
            unit: .oz
        )
        let dto = MeasurementDTO(from: measurement)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(dto)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Then
        XCTAssertEqual(json["occurrence_id"] as? String, occurrenceId.uuidString)
        XCTAssertEqual(json["value"] as? Double, 250.0)
        XCTAssertEqual(json["unit"] as? String, "oz")
    }

    // MARK: - Edge Cases

    func testNilOccurrenceId() {
        // Given
        let measurement = TestFixtures.makeMeasurement(occurrenceId: nil)

        // When
        let dto = MeasurementDTO(from: measurement)
        let converted = dto.toDomain

        // Then
        XCTAssertNil(converted.occurrenceId)
    }

    func testZeroValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 0.0)

        // When
        let dto = MeasurementDTO(from: measurement)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.value, 0.0)
    }

    func testLargeValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 999999.99)

        // When
        let dto = MeasurementDTO(from: measurement)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.value, 999999.99)
    }

    func testNegativeValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: -10.0)

        // When
        let dto = MeasurementDTO(from: measurement)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.value, -10.0)
    }

    // MARK: - Unit Type Tests

    func testVolumeUnits() {
        // Given
        let units: [UnitKind] = [.ml, .l, .oz]

        for unit in units {
            // When
            let measurement = TestFixtures.makeMeasurement(unit: unit)
            let dto = MeasurementDTO(from: measurement)
            let converted = dto.toDomain

            // Then
            XCTAssertEqual(converted.unit, unit)
            XCTAssertTrue(converted.unit.isVolume)
        }
    }

    func testWeightUnits() {
        // Given
        let units: [UnitKind] = [.kg, .lb]

        for unit in units {
            // When
            let measurement = TestFixtures.makeMeasurement(unit: unit)
            let dto = MeasurementDTO(from: measurement)
            let converted = dto.toDomain

            // Then
            XCTAssertEqual(converted.unit, unit)
            XCTAssertTrue(converted.unit.isWeight)
        }
    }

    func testTimeUnits() {
        // Given
        let units: [UnitKind] = [.minutes, .hours]

        for unit in units {
            // When
            let measurement = TestFixtures.makeMeasurement(unit: unit)
            let dto = MeasurementDTO(from: measurement)
            let converted = dto.toDomain

            // Then
            XCTAssertEqual(converted.unit, unit)
            XCTAssertTrue(converted.unit.isTime)
        }
    }
}

// MARK: - GoalMeasureTargetDTOTests

final class GoalMeasureTargetDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let target = TestFixtures.makeMeasureTarget(
            targetValue: 2000.0,
            unit: .ml
        )

        // When
        let dto = GoalMeasureTargetDTO(from: target)

        // Then
        XCTAssertEqual(dto.id, target.id)
        XCTAssertEqual(dto.userId, target.userId)
        XCTAssertEqual(dto.goalId, target.goalId)
        XCTAssertEqual(dto.targetValue, 2000.0)
        XCTAssertEqual(dto.unit, "ml")
        XCTAssertNotNil(dto.effectiveFrom)
        XCTAssertNil(dto.effectiveTo)
    }

    func testInitFromDomainWithEffectiveTo() {
        // Given
        let target = TestFixtures.makeMeasureTarget(
            effectiveTo: TestFixtures.laterDate
        )

        // When
        let dto = GoalMeasureTargetDTO(from: target)

        // Then
        XCTAssertNotNil(dto.effectiveTo)
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = TestFixtures.makeMeasureTargetDTO(
            targetValue: 3000.0,
            unit: "ml"
        )

        // When
        let target = dto.toDomain

        // Then
        XCTAssertEqual(target.id, dto.id)
        XCTAssertEqual(target.userId, dto.userId)
        XCTAssertEqual(target.goalId, dto.goalId)
        XCTAssertEqual(target.targetValue, 3000.0)
        XCTAssertEqual(target.unit, .ml)
    }

    func testToDomainWithUnknownUnit() {
        // Given
        let dto = GoalMeasureTargetDTO(
            id: UUID(),
            userId: TestFixtures.userId,
            goalId: TestFixtures.goalId,
            targetValue: 100.0,
            unit: "unknown",
            effectiveFrom: Date(),
            effectiveTo: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let target = dto.toDomain

        // Then - Should fall back to .count
        XCTAssertEqual(target.unit, .count)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalTarget = TestFixtures.makeMeasureTarget(
            targetValue: 8.0,
            unit: .l,
            effectiveTo: TestFixtures.laterDate
        )

        // When
        let dto = GoalMeasureTargetDTO(from: originalTarget)
        let convertedTarget = dto.toDomain

        // Then
        XCTAssertEqual(convertedTarget.id, originalTarget.id)
        XCTAssertEqual(convertedTarget.userId, originalTarget.userId)
        XCTAssertEqual(convertedTarget.goalId, originalTarget.goalId)
        XCTAssertEqual(convertedTarget.targetValue, originalTarget.targetValue)
        XCTAssertEqual(convertedTarget.unit, originalTarget.unit)
        XCTAssertEqual(
            convertedTarget.effectiveFrom.timeIntervalSince1970,
            originalTarget.effectiveFrom.timeIntervalSince1970,
            accuracy: 0.001
        )
        XCTAssertEqual(
            convertedTarget.effectiveTo?.timeIntervalSince1970,
            originalTarget.effectiveTo?.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    // MARK: - Codable Tests

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "user_id": "\(TestFixtures.userId.uuidString)",
            "goal_id": "\(TestFixtures.goalId.uuidString)",
            "target_value": 2500.0,
            "unit": "ml",
            "effective_from": "2023-11-14T00:00:00Z",
            "effective_to": null,
            "created_at": "2023-11-14T12:00:00Z",
            "updated_at": "2023-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let dto = try decoder.decode(GoalMeasureTargetDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.targetValue, 2500.0)
        XCTAssertEqual(dto.unit, "ml")
        XCTAssertNil(dto.effectiveTo)
    }

    // MARK: - Edge Cases

    func testNilEffectiveTo() {
        // Given
        let target = TestFixtures.makeMeasureTarget(effectiveTo: nil)

        // When
        let dto = GoalMeasureTargetDTO(from: target)
        let converted = dto.toDomain

        // Then
        XCTAssertNil(converted.effectiveTo)
    }

    func testZeroTargetValue() {
        // Given
        let target = TestFixtures.makeMeasureTarget(targetValue: 0.0)

        // When
        let dto = GoalMeasureTargetDTO(from: target)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.targetValue, 0.0)
    }

    func testLargeTargetValue() {
        // Given
        let target = TestFixtures.makeMeasureTarget(targetValue: 1000000.0)

        // When
        let dto = GoalMeasureTargetDTO(from: target)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.targetValue, 1000000.0)
    }

    func testAllUnitTypes() {
        // Given
        let units: [UnitKind] = [.count, .ml, .l, .oz, .kg, .lb, .minutes, .hours]

        for unit in units {
            // When
            let target = TestFixtures.makeMeasureTarget(unit: unit)
            let dto = GoalMeasureTargetDTO(from: target)
            let converted = dto.toDomain

            // Then
            XCTAssertEqual(converted.unit, unit, "Unit \(unit.rawValue) should round-trip correctly")
        }
    }
}
