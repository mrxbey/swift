import XCTest
import SwiftData
@testable import HabitTracker

@MainActor
final class CacheServiceTests: XCTestCase {
    var cacheService: CacheService!

    override func setUp() async throws {
        try await super.setUp()
        // Create in-memory cache service for testing
        cacheService = try CacheService()
    }

    override func tearDown() async throws {
        // Clean up cache between tests
        try cacheService.clearAll()
        cacheService = nil
        try await super.tearDown()
    }

    // MARK: - Area Operations

    func testSaveAndFetchArea() throws {
        // Given
        let area = TestFixtures.makeArea(name: "Test Area")

        // When
        try cacheService.saveArea(area, syncState: .synced)
        let fetched = try cacheService.fetchAreas(userId: TestFixtures.userId)

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test Area")
    }

    func testFetchAreaById() throws {
        // Given
        let area = TestFixtures.makeArea()
        try cacheService.saveArea(area, syncState: .synced)

        // When
        let fetched = try cacheService.fetchArea(id: area.id)

        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, area.id)
        XCTAssertEqual(fetched?.name, area.name)
    }

    func testUpdateArea() throws {
        // Given
        let originalArea = TestFixtures.makeArea(name: "Original")
        try cacheService.saveArea(originalArea, syncState: .synced)

        // When
        let updatedArea = TestFixtures.makeArea(
            id: originalArea.id,
            name: "Updated"
        )
        try cacheService.saveArea(updatedArea, syncState: .pending)

        // Then
        let fetched = try cacheService.fetchArea(id: originalArea.id)
        XCTAssertEqual(fetched?.name, "Updated")
    }

    func testDeleteArea() throws {
        // Given
        let area = TestFixtures.makeArea()
        try cacheService.saveArea(area, syncState: .synced)

        // When
        try cacheService.deleteArea(id: area.id)

        // Then
        let fetched = try cacheService.fetchArea(id: area.id)
        XCTAssertNil(fetched)
    }

    func testFetchMultipleAreas() throws {
        // Given
        let area1 = TestFixtures.makeArea(
            id: UUID(),
            name: "Area 1"
        )
        let area2 = TestFixtures.makeArea(
            id: UUID(),
            name: "Area 2"
        )

        try cacheService.saveArea(area1, syncState: .synced)
        try cacheService.saveArea(area2, syncState: .synced)

        // When
        let fetched = try cacheService.fetchAreas(userId: TestFixtures.userId)

        // Then
        XCTAssertEqual(fetched.count, 2)
    }

    // MARK: - Goal Operations

    func testSaveAndFetchGoal() throws {
        // Given
        let goal = TestFixtures.makeGoal(title: "Test Goal")

        // When
        try cacheService.saveGoal(goal, syncState: .synced)
        let fetched = try cacheService.fetchGoals(userId: TestFixtures.userId)

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Test Goal")
    }

    func testFetchGoalsByAreaId() throws {
        // Given
        let areaId = UUID()
        let goal1 = TestFixtures.makeGoal(
            id: UUID(),
            areaId: areaId,
            title: "Goal 1"
        )
        let goal2 = TestFixtures.makeGoal(
            id: UUID(),
            areaId: areaId,
            title: "Goal 2"
        )
        let goalOtherArea = TestFixtures.makeGoal(
            id: UUID(),
            areaId: UUID(),
            title: "Other Area Goal"
        )

        try cacheService.saveGoal(goal1, syncState: .synced)
        try cacheService.saveGoal(goal2, syncState: .synced)
        try cacheService.saveGoal(goalOtherArea, syncState: .synced)

        // When
        let fetched = try cacheService.fetchGoals(areaId: areaId)

        // Then
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.allSatisfy { $0.areaId == areaId })
    }

    func testDeleteGoal() throws {
        // Given
        let goal = TestFixtures.makeGoal()
        try cacheService.saveGoal(goal, syncState: .synced)

        // When
        try cacheService.deleteGoal(id: goal.id)

        // Then
        let fetched = try cacheService.fetchGoal(id: goal.id)
        XCTAssertNil(fetched)
    }

    // MARK: - Occurrence Operations

    func testSaveAndFetchOccurrence() throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence()

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)
        let fetched = try cacheService.fetchOccurrences(
            userId: TestFixtures.userId,
            date: TestFixtures.baseDate
        )

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, occurrence.id)
    }

    func testFetchOccurrencesForDate() throws {
        // Given
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let occurrenceToday = TestFixtures.makeOccurrence(
            id: UUID(),
            scheduledDate: today
        )
        let occurrenceTomorrow = TestFixtures.makeOccurrence(
            id: UUID(),
            scheduledDate: tomorrow
        )

        try cacheService.saveOccurrence(occurrenceToday, syncState: .synced)
        try cacheService.saveOccurrence(occurrenceTomorrow, syncState: .synced)

        // When
        let fetchedToday = try cacheService.fetchOccurrences(
            userId: TestFixtures.userId,
            date: today
        )

        // Then
        XCTAssertEqual(fetchedToday.count, 1)
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(fetchedToday.first!.scheduledDate, inSameDayAs: today))
    }

    // MARK: - Measurement Operations

    func testSaveAndFetchMeasurement() throws {
        // Given
        let measurement = TestFixtures.makeMeasurement(value: 500.0)

        // When
        try cacheService.saveMeasurement(measurement, syncState: .synced)
        let fetched = try cacheService.fetchMeasurements(goalId: TestFixtures.goalId)

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.value, 500.0)
    }

    func testDeleteMeasurement() throws {
        // Given
        let measurement = TestFixtures.makeMeasurement()
        try cacheService.saveMeasurement(measurement, syncState: .synced)

        // When
        try cacheService.deleteMeasurement(id: measurement.id)

        // Then
        let fetched = try cacheService.fetchMeasurements(goalId: TestFixtures.goalId)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Sync State Management

    func testFetchPendingAreas() throws {
        // Given
        let syncedArea = TestFixtures.makeArea(
            id: UUID(),
            name: "Synced"
        )
        let pendingArea = TestFixtures.makeArea(
            id: UUID(),
            name: "Pending"
        )

        try cacheService.saveArea(syncedArea, syncState: .synced)
        try cacheService.saveArea(pendingArea, syncState: .pending)

        // When
        let pending = try cacheService.fetchPendingAreas()

        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.name, "Pending")
    }

    func testFetchPendingGoals() throws {
        // Given
        let syncedGoal = TestFixtures.makeGoal(
            id: UUID(),
            title: "Synced"
        )
        let pendingGoal = TestFixtures.makeGoal(
            id: UUID(),
            title: "Pending"
        )

        try cacheService.saveGoal(syncedGoal, syncState: .synced)
        try cacheService.saveGoal(pendingGoal, syncState: .pending)

        // When
        let pending = try cacheService.fetchPendingGoals()

        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.title, "Pending")
    }

    func testFetchPendingOccurrences() throws {
        // Given
        let syncedOccurrence = TestFixtures.makeOccurrence(id: UUID())
        let pendingOccurrence = TestFixtures.makeOccurrence(id: UUID())

        try cacheService.saveOccurrence(syncedOccurrence, syncState: .synced)
        try cacheService.saveOccurrence(pendingOccurrence, syncState: .pending)

        // When
        let pending = try cacheService.fetchPendingOccurrences()

        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, pendingOccurrence.id)
    }

    func testFetchPendingMeasurements() throws {
        // Given
        let syncedMeasurement = TestFixtures.makeMeasurement(id: UUID())
        let pendingMeasurement = TestFixtures.makeMeasurement(id: UUID())

        try cacheService.saveMeasurement(syncedMeasurement, syncState: .synced)
        try cacheService.saveMeasurement(pendingMeasurement, syncState: .pending)

        // When
        let pending = try cacheService.fetchPendingMeasurements()

        // Then
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, pendingMeasurement.id)
    }

    // MARK: - Clear Operations

    func testClearAll() throws {
        // Given
        try cacheService.saveArea(TestFixtures.makeArea(), syncState: .synced)
        try cacheService.saveGoal(TestFixtures.makeGoal(), syncState: .synced)
        try cacheService.saveOccurrence(TestFixtures.makeOccurrence(), syncState: .synced)
        try cacheService.saveMeasurement(TestFixtures.makeMeasurement(), syncState: .synced)

        // When
        try cacheService.clearAll()

        // Then
        XCTAssertTrue(try cacheService.fetchAreas(userId: TestFixtures.userId).isEmpty)
        XCTAssertTrue(try cacheService.fetchGoals(userId: TestFixtures.userId).isEmpty)
        XCTAssertTrue(try cacheService.fetchPendingOccurrences().isEmpty)
        XCTAssertTrue(try cacheService.fetchPendingMeasurements().isEmpty)
    }

    func testClearSyncedDataOlderThanDate() throws {
        // Given
        let oldDate = Date(timeIntervalSince1970: 1000000)
        let recentDate = Date()

        // Create old synced area
        let oldArea = TestFixtures.makeArea(
            id: UUID(),
            name: "Old",
            createdAt: oldDate
        )
        try cacheService.saveArea(oldArea, syncState: .synced)

        // Create recent synced area
        let recentArea = TestFixtures.makeArea(
            id: UUID(),
            name: "Recent",
            createdAt: recentDate
        )
        try cacheService.saveArea(recentArea, syncState: .synced)

        // When
        let cutoffDate = Date(timeIntervalSince1970: 2000000)
        try cacheService.clearSyncedData(olderThan: cutoffDate)

        // Then
        let remaining = try cacheService.fetchAreas(userId: TestFixtures.userId)
        // Recent area should remain
        XCTAssertTrue(remaining.contains { $0.name == "Recent" })
    }

    // MARK: - Concurrent Operations

    func testConcurrentSaves() async throws {
        // Given
        let area1 = TestFixtures.makeArea(id: UUID(), name: "Area 1")
        let area2 = TestFixtures.makeArea(id: UUID(), name: "Area 2")
        let area3 = TestFixtures.makeArea(id: UUID(), name: "Area 3")

        // When - Save concurrently
        async let save1: Void = cacheService.saveArea(area1, syncState: .synced)
        async let save2: Void = cacheService.saveArea(area2, syncState: .synced)
        async let save3: Void = cacheService.saveArea(area3, syncState: .synced)

        let _ = try await (save1, save2, save3)

        // Then
        let fetched = try cacheService.fetchAreas(userId: TestFixtures.userId)
        XCTAssertEqual(fetched.count, 3)
    }
}
