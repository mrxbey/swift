import XCTest
import SwiftData
@testable import HabitTracker

final class CachedMeasurementTests: XCTestCase {

    // MARK: - Domain to Cache Conversion

    func testInitFromDomain() {
        // Given
        let measurement = TestFixtures.makeMeasurement(
            value: 500.0,
            unit: .ml
        )

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)

        // Then
        XCTAssertEqual(cached.id, measurement.id)
        XCTAssertEqual(cached.userId, measurement.userId)
        XCTAssertEqual(cached.goalId, measurement.goalId)
        XCTAssertEqual(cached.occurrenceId, measurement.occurrenceId)
        XCTAssertEqual(cached.value, 500.0)
        XCTAssertEqual(cached.unit, "ml")
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithPendingState() {
        // Given
        let measurement = TestFixtures.makeMeasurement()

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithOccurrenceId() {
        // Given
        let occurrenceId = UUID()
        let measurement = TestFixtures.makeMeasurement(
            occurrenceId: occurrenceId,
            value: 750.0,
            unit: .oz
        )

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)

        // Then
        XCTAssertEqual(cached.occurrenceId, occurrenceId)
        XCTAssertEqual(cached.value, 750.0)
        XCTAssertEqual(cached.unit, "oz")
    }

    func testInitFromDomainWithoutOccurrenceId() {
        // Given
        let measurement = TestFixtures.makeMeasurement(occurrenceId: nil)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)

        // Then
        XCTAssertNil(cached.occurrenceId)
    }

    // MARK: - Cache to Domain Conversion

    func testToDomain() {
        // Given
        let measurement = TestFixtures.makeMeasurement(
            value: 2.5,
            unit: .l
        )
        let cached = CachedMeasurement(from: measurement, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.id, measurement.id)
        XCTAssertEqual(converted.userId, measurement.userId)
        XCTAssertEqual(converted.goalId, measurement.goalId)
        XCTAssertEqual(converted.occurrenceId, measurement.occurrenceId)
        XCTAssertEqual(converted.value, 2.5)
        XCTAssertEqual(converted.unit, .l)
    }

    func testToDomainWithUnknownUnitDefaultsToCount() {
        // Given
        let cached = CachedMeasurement(
            id: TestFixtures.measurementId,
            userId: TestFixtures.userId,
            goalId: TestFixtures.goalId,
            value: 100.0,
            unit: "unknown_unit",
            recordedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let measurement = cached.toDomain()

        // Then
        XCTAssertEqual(measurement.unit, .count)
    }

    // MARK: - UnitKind Conversion

    func testUnitKindMLConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .ml)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .ml)
    }

    func testUnitKindLConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .l)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .l)
    }

    func testUnitKindOzConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .oz)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .oz)
    }

    func testUnitKindKgConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .kg)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .kg)
    }

    func testUnitKindLbConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .lb)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .lb)
    }

    func testUnitKindMinutesConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .minutes)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .minutes)
    }

    func testUnitKindHoursConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .hours)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .hours)
    }

    func testUnitKindCountConversion() {
        // Given
        let measurement = TestFixtures.makeMeasurement(unit: .count)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.unit, .count)
    }

    // MARK: - Update Method

    func testUpdateFromDomain() {
        // Given
        let originalMeasurement = TestFixtures.makeMeasurement(value: 100.0)
        let cached = CachedMeasurement(from: originalMeasurement, syncState: .synced)

        let updatedMeasurement = TestFixtures.makeMeasurement(
            id: originalMeasurement.id,
            value: 250.0,
            unit: .oz,
            updatedAt: TestFixtures.laterDate
        )

        // When
        cached.update(from: updatedMeasurement, syncState: .pending)

        // Then
        XCTAssertEqual(cached.value, 250.0)
        XCTAssertEqual(cached.unit, "oz")
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertEqual(
            cached.updatedAt.timeIntervalSince1970,
            TestFixtures.laterDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testUpdatePreservesSyncMetadata() {
        // Given
        let measurement = TestFixtures.makeMeasurement()
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let originalSyncDate = cached.lastSyncedAt

        let updatedMeasurement = TestFixtures.makeMeasurement(
            id: measurement.id,
            value: 1000.0
        )

        // When
        cached.update(from: updatedMeasurement, syncState: .synced)

        // Then
        XCTAssertEqual(cached.value, 1000.0)
        XCTAssertNotNil(cached.lastSyncedAt)
        // Sync date should be updated
        if let originalDate = originalSyncDate {
            XCTAssertGreaterThanOrEqual(
                cached.lastSyncedAt?.timeIntervalSince1970 ?? 0,
                originalDate.timeIntervalSince1970
            )
        }
    }

    // MARK: - Sync State Management

    func testSyncStateSynced() {
        // Given
        let measurement = TestFixtures.makeMeasurement()

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)

        // Then
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testSyncStatePending() {
        // Given
        let measurement = TestFixtures.makeMeasurement()

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testSyncStateFailed() {
        // Given
        let measurement = TestFixtures.makeMeasurement()

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .failed)

        // Then
        XCTAssertEqual(cached.syncState, "failed")
        XCTAssertNil(cached.lastSyncedAt)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let occurrenceId = UUID()
        let originalMeasurement = TestFixtures.makeMeasurement(
            occurrenceId: occurrenceId,
            value: 1200.0,
            unit: .ml
        )

        // When
        let cached = CachedMeasurement(from: originalMeasurement, syncState: .synced)
        let convertedMeasurement = cached.toDomain()

        // Then
        XCTAssertEqual(convertedMeasurement.id, originalMeasurement.id)
        XCTAssertEqual(convertedMeasurement.userId, originalMeasurement.userId)
        XCTAssertEqual(convertedMeasurement.goalId, originalMeasurement.goalId)
        XCTAssertEqual(convertedMeasurement.occurrenceId, originalMeasurement.occurrenceId)
        XCTAssertEqual(convertedMeasurement.value, originalMeasurement.value)
        XCTAssertEqual(convertedMeasurement.unit, originalMeasurement.unit)
    }

    // MARK: - Edge Cases

    func testNilOccurrenceId() {
        // Given
        let measurement = TestFixtures.makeMeasurement(occurrenceId: nil)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertNil(converted.occurrenceId)
    }

    func testZeroValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 0.0)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.value, 0.0)
    }

    func testLargeValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 999999.99)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.value, 999999.99)
    }

    func testNegativeValue() {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: -10.0)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.value, -10.0)
    }

    func testDecimalPrecision() {
        // Test that decimal values are preserved accurately
        let testValues = [0.1, 0.01, 0.001, 123.456, 99.99, 1.23456789]

        for value in testValues {
            // Given
            let measurement = TestFixtures.makeMeasurement(value: value)

            // When
            let cached = CachedMeasurement(from: measurement, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.value, value, accuracy: 0.00000001)
        }
    }

    func testAllUnitTypes() {
        // Test all UnitKind enum cases
        let units: [UnitKind] = [.count, .ml, .l, .oz, .kg, .lb, .minutes, .hours]

        for unit in units {
            // Given
            let measurement = TestFixtures.makeMeasurement(unit: unit)

            // When
            let cached = CachedMeasurement(from: measurement, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.unit, unit, "Unit \(unit.rawValue) should round-trip correctly")
        }
    }

    func testRecordedAtDatePreservation() {
        // Given
        let recordedDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let measurement = TestFixtures.makeMeasurement(recordedAt: recordedDate)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(
            converted.recordedAt.timeIntervalSince1970,
            recordedDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testCreatedAtDatePreservation() {
        // Given
        let createdDate = Date().addingTimeInterval(-86400) // 1 day ago
        let measurement = TestFixtures.makeMeasurement(createdAt: createdDate)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(
            converted.createdAt.timeIntervalSince1970,
            createdDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testUpdatedAtDatePreservation() {
        // Given
        let updatedDate = Date()
        let measurement = TestFixtures.makeMeasurement(updatedAt: updatedDate)

        // When
        let cached = CachedMeasurement(from: measurement, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(
            converted.updatedAt.timeIntervalSince1970,
            updatedDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }
}
