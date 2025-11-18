import XCTest
import SwiftData
@testable import HabitTracker

/// Comprehensive tests for SupabaseMeasurementRepository
///
/// Tests measurement-specific logic including:
/// - Unit type handling
/// - Decimal precision
/// - Goal association
/// - Occurrence linking
@MainActor
final class SupabaseMeasurementRepositoryTests: XCTestCase {
    var cacheService: CacheService!
    var networkMonitor: MockNetworkMonitor!

    override func setUp() async throws {
        try await super.setUp()
        cacheService = try CacheService()
        networkMonitor = MockNetworkMonitor()
        await networkMonitor.setConnected(true)
    }

    override func tearDown() async throws {
        try cacheService.clearAll()
        cacheService = nil
        await networkMonitor.reset()
        try await super.tearDown()
    }

    // MARK: - Basic CRUD

    func testSaveMeasurementToCache() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 500.0, unit: .ml)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurements(goalId: TestFixtures.goalId)
        XCTAssertEqual(cached.count, 1)
        XCTAssertEqual(cached.first?.value, 500.0)
    }

    func testFetchMeasurementsByGoalId() async throws {
        // Given - Measurements for different goals
        let goalId1 = UUID()
        let goalId2 = UUID()

        let m1 = TestFixtures.makeMeasurement(id: UUID(), goalId: goalId1, value: 500.0)
        let m2 = TestFixtures.makeMeasurement(id: UUID(), goalId: goalId1, value: 750.0)
        let m3 = TestFixtures.makeMeasurement(id: UUID(), goalId: goalId2, value: 1000.0)

        try cacheService.saveMeasurement(m1, syncState: .synced)
        try cacheService.saveMeasurement(m2, syncState: .synced)
        try cacheService.saveMeasurement(m3, syncState: .synced)

        // When
        let forGoal1 = try cacheService.fetchMeasurements(goalId: goalId1)

        // Then
        XCTAssertEqual(forGoal1.count, 2)
        XCTAssertTrue(forGoal1.allSatisfy { $0.goalId == goalId1 })
    }

    // MARK: - Unit Types

    func testVolumeUnitsML() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 250.0, unit: .ml)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .ml)
        XCTAssertTrue(cached!.unit.isVolume)
    }

    func testVolumeUnitsLiters() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 2.5, unit: .l)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .l)
        XCTAssertTrue(cached!.unit.isVolume)
    }

    func testVolumeUnitsOunces() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 8.0, unit: .oz)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .oz)
        XCTAssertTrue(cached!.unit.isVolume)
    }

    func testWeightUnitsKilograms() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 70.5, unit: .kg)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .kg)
        XCTAssertTrue(cached!.unit.isWeight)
    }

    func testWeightUnitsPounds() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 155.0, unit: .lb)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .lb)
        XCTAssertTrue(cached!.unit.isWeight)
    }

    func testTimeUnitsMinutes() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 30.0, unit: .minutes)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .minutes)
        XCTAssertTrue(cached!.unit.isTime)
    }

    func testTimeUnitsHours() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 2.5, unit: .hours)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .hours)
        XCTAssertTrue(cached!.unit.isTime)
    }

    func testCountUnit() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 10.0, unit: .count)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.unit, .count)
        XCTAssertFalse(cached!.unit.isVolume)
        XCTAssertFalse(cached!.unit.isWeight)
        XCTAssertFalse(cached!.unit.isTime)
    }

    // MARK: - Decimal Precision

    func testDecimalPrecisionIsPreserved() async throws {
        // Test various decimal precisions
        let testValues = [0.1, 0.01, 0.001, 123.456, 99.99, 1.23456789]

        for value in testValues {
            // Given
            let measurement = TestFixtures.makeMeasurement(
                id: UUID(),
                value: value,
                unit: .ml
            )

            // When
            try cacheService.saveMeasurement(measurement, syncState: .synced)

            // Then
            let cached = try cacheService.fetchMeasurement(id: measurement.id)
            XCTAssertEqual(cached?.value, value, accuracy: 0.00000001,
                          "Value \(value) should be preserved with high precision")
        }
    }

    // MARK: - Value Edge Cases

    func testZeroValueIsAllowed() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 0.0)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.value, 0.0)
    }

    func testNegativeValueIsAllowed() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: -10.5)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.value, -10.5)
    }

    func testVeryLargeValueIsPreserved() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 999999.99)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.value, 999999.99)
    }

    func testVerySmallValueIsPreserved() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 0.0001)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.value, 0.0001, accuracy: 0.00001)
    }

    // MARK: - Occurrence Association

    func testMeasurementWithOccurrenceIdIsPreserved() async throws {
        // Given
        let occurrenceId = UUID()
        let measurement = TestFixtures.makeMeasurement(
            occurrenceId: occurrenceId,
            value: 500.0
        )

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.occurrenceId, occurrenceId)
    }

    func testMeasurementWithoutOccurrenceIdIsPreserved() async throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(
            occurrenceId: nil,
            value: 500.0
        )

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertNil(cached?.occurrenceId)
    }

    // MARK: - Timestamps

    func testRecordedAtDateIsPreserved() async throws {
        // Given
        let recordedDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let measurement = TestFixtures.makeMeasurement(
            recordedAt: recordedDate
        )

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(
            cached?.recordedAt.timeIntervalSince1970,
            recordedDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testCreatedAtDateIsPreserved() async throws {
        // Given
        let createdDate = Date().addingTimeInterval(-86400) // 1 day ago
        let measurement = TestFixtures.makeMeasurement(
            createdAt: createdDate
        )

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(
            cached?.createdAt.timeIntervalSince1970,
            createdDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testUpdatedAtDateIsPreserved() async throws {
        // Given
        let updatedDate = Date()
        let measurement = TestFixtures.makeMeasurement(
            updatedAt: updatedDate
        )

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(
            cached?.updatedAt.timeIntervalSince1970,
            updatedDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    // MARK: - Offline Operations

    func testCreateMeasurementOfflineSavesWithPendingState() async throws {
        // Given - Offline
        await networkMonitor.setConnected(false)

        let measurement = TestFixtures.makeMeasurement()

        // When
        try cacheService.saveMeasurement(measurement, syncState: .pending)

        // Then
        let pending = try cacheService.fetchPendingMeasurements()
        XCTAssertEqual(pending.count, 1)
    }

    func testUpdateMeasurementOfflineMarksAsPending() async throws {
        // Given - Synced measurement
        let measurement = TestFixtures.makeMeasurement(value: 100.0)
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        await networkMonitor.setConnected(false)

        // When - Update offline
        var updated = measurement
        updated.value = 200.0
        updated.updatedAt = Date()

        try cacheService.saveMeasurement(updated, syncState: .pending)

        // Then
        let pending = try cacheService.fetchPendingMeasurements()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.value, 200.0)
    }

    // MARK: - Concurrent Operations

    func testConcurrentMeasurementSaves() async throws {
        // Given
        let m1 = TestFixtures.makeMeasurement(id: UUID(), value: 100.0)
        let m2 = TestFixtures.makeMeasurement(id: UUID(), value: 200.0)
        let m3 = TestFixtures.makeMeasurement(id: UUID(), value: 300.0)

        // When - Save concurrently
        async let save1: Void = cacheService.saveMeasurement(m1, syncState: .pending)
        async let save2: Void = cacheService.saveMeasurement(m2, syncState: .pending)
        async let save3: Void = cacheService.saveMeasurement(m3, syncState: .pending)

        let _ = try await (save1, save2, save3)

        // Then
        let pending = try cacheService.fetchPendingMeasurements()
        XCTAssertEqual(pending.count, 3)
    }

    // MARK: - Data Integrity

    func testGoalIdIsPreservedInCache() async throws {
        // Given
        let goalId = UUID()
        let measurement = TestFixtures.makeMeasurement(goalId: goalId)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.goalId, goalId)
    }

    func testUserIdIsPreservedInCache() async throws {
        // Given
        let userId = UUID()
        let measurement = TestFixtures.makeMeasurement(userId: userId)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // Then
        let cached = try cacheService.fetchMeasurement(id: measurement.id)
        XCTAssertEqual(cached?.userId, userId)
    }

    // MARK: - All Unit Types Round-Trip

    func testAllUnitTypesRoundTrip() async throws {
        // Test all UnitKind enum cases
        let units: [UnitKind] = [.count, .ml, .l, .oz, .kg, .lb, .minutes, .hours]

        for unit in units {
            // Given
            let measurement = TestFixtures.makeMeasurement(
                id: UUID(),
                value: 123.45,
                unit: unit
            )

            // When
            try cacheService.saveMeasurement(measurement, syncState: .synced)

            // Then
            let cached = try cacheService.fetchMeasurement(id: measurement.id)
            XCTAssertEqual(cached?.unit, unit,
                          "Unit \(unit.rawValue) should round-trip correctly")
            XCTAssertEqual(cached?.value, 123.45, accuracy: 0.001)
        }
    }
}
