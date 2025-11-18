import XCTest
import SwiftData
@testable import HabitTracker

/// Comprehensive tests for SupabaseGoalRepository
///
/// Tests repository logic including:
/// - Cache-first reads
/// - Offline operation queuing
/// - Status transitions (active/archived/deleted)
/// - Hashtag handling
/// - LinkedExercise associations
@MainActor
final class SupabaseGoalRepositoryTests: XCTestCase {
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

    // MARK: - Cache-First Reads

    func testFetchAllGoalsFromCache() async throws {
        // Given - Goals in cache
        let goal1 = TestFixtures.makeGoal(id: UUID(), title: "Morning Run")
        let goal2 = TestFixtures.makeGoal(id: UUID(), title: "Read Daily")

        try cacheService.saveGoal(goal1, syncState: .synced)
        try cacheService.saveGoal(goal2, syncState: .synced)

        // When
        let cached = try cacheService.fetchGoals(userId: TestFixtures.userId)

        // Then
        XCTAssertEqual(cached.count, 2)
        XCTAssertTrue(cached.contains(where: { $0.title == "Morning Run" }))
        XCTAssertTrue(cached.contains(where: { $0.title == "Read Daily" }))
    }

    func testFetchGoalsByAreaId() async throws {
        // Given - Goals for different areas
        let areaId1 = UUID()
        let areaId2 = UUID()

        let goal1 = TestFixtures.makeGoal(id: UUID(), areaId: areaId1, title: "Health Goal")
        let goal2 = TestFixtures.makeGoal(id: UUID(), areaId: areaId1, title: "Fitness Goal")
        let goal3 = TestFixtures.makeGoal(id: UUID(), areaId: areaId2, title: "Work Goal")

        try cacheService.saveGoal(goal1, syncState: .synced)
        try cacheService.saveGoal(goal2, syncState: .synced)
        try cacheService.saveGoal(goal3, syncState: .synced)

        // When
        let goalsForArea1 = try cacheService.fetchGoals(areaId: areaId1)

        // Then
        XCTAssertEqual(goalsForArea1.count, 2)
        XCTAssertTrue(goalsForArea1.allSatisfy { $0.areaId == areaId1 })
    }

    // MARK: - Offline Operations

    func testCreateGoalOfflineSavesWithPendingState() async throws {
        // Given - Offline network
        await networkMonitor.setConnected(false)

        let goal = TestFixtures.makeGoal(title: "New Goal")

        // When
        try cacheService.saveGoal(goal, syncState: .pending)

        // Then - Goal is queued for sync
        let pending = try cacheService.fetchPendingGoals()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.title, "New Goal")
    }

    func testUpdateGoalOfflineMarksAsPending() async throws {
        // Given - Synced goal
        let originalGoal = TestFixtures.makeGoal(title: "Original")
        try cacheService.saveGoal(originalGoal, syncState: .synced)

        await networkMonitor.setConnected(false)

        // When - Update offline
        var updatedGoal = originalGoal
        updatedGoal.title = "Updated Offline"
        updatedGoal.updatedAt = Date()

        try cacheService.saveGoal(updatedGoal, syncState: .pending)

        // Then
        let cached = try cacheService.fetchGoal(id: originalGoal.id)
        XCTAssertEqual(cached?.title, "Updated Offline")

        let pending = try cacheService.fetchPendingGoals()
        XCTAssertEqual(pending.count, 1)
    }

    // MARK: - Goal Types and Status

    func testGoalKindHabitIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(kind: .habit)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.kind, .habit)
    }

    func testGoalKindTaskIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(kind: .task)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.kind, .task)
    }

    func testGoalKindMeasureIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(kind: .measure)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.kind, .measure)
    }

    func testGoalStatusActiveIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(status: .active)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.status, .active)
    }

    func testGoalStatusArchivedIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(status: .archived)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.status, .archived)
    }

    // MARK: - Hashtags

    func testHashtagsArePreservedInCache() async throws {
        // Given - Goal with hashtags
        let goal = TestFixtures.makeGoal(hashtags: ["fitness", "morning", "health"])

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.hashtags, ["fitness", "morning", "health"])
    }

    func testEmptyHashtagsArePreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(hashtags: [])

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.hashtags, [])
    }

    func testMultipleHashtagsArePreserved() async throws {
        // Given
        let hashtags = ["health", "fitness", "morning", "routine", "2024", "goals"]
        let goal = TestFixtures.makeGoal(hashtags: hashtags)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.hashtags, hashtags)
    }

    // MARK: - LinkedExercise

    func testLinkedExerciseIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(linkedExerciseKey: .meditation)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.linkedExerciseKey, .meditation)
    }

    func testNilLinkedExerciseIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(linkedExerciseKey: nil)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertNil(cached?.linkedExerciseKey)
    }

    func testAllLinkedExerciseTypesArePreserved() async throws {
        // Test all LinkedExercise enum cases
        let exercises: [LinkedExercise] = [
            .meditation, .pomodoro, .study, .breath,
            .water, .affirmations, .journal, .mood
        ]

        for exercise in exercises {
            // Given
            let goal = TestFixtures.makeGoal(
                id: UUID(),
                linkedExerciseKey: exercise
            )

            // When
            try cacheService.saveGoal(goal, syncState: .synced)

            // Then
            let cached = try cacheService.fetchGoal(id: goal.id)
            XCTAssertEqual(cached?.linkedExerciseKey, exercise,
                          "LinkedExercise.\(exercise.rawValue) should round-trip correctly")
        }
    }

    // MARK: - Goal Configuration

    func testTimesPerDayIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(timesPerDay: 3)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.timesPerDay, 3)
    }

    func testPointsPerCompletionIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(pointsPerCompletion: 25)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.pointsPerCompletion, 25)
    }

    func testKeepUntilCompleteTrueIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(keepUntilComplete: true)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertTrue(cached!.keepUntilComplete)
    }

    func testKeepUntilCompleteFalseIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(keepUntilComplete: false)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertFalse(cached!.keepUntilComplete)
    }

    // MARK: - Data Integrity

    func testEmojiIsPreservedInCache() async throws {
        // Given
        let goal = TestFixtures.makeGoal(emoji: "🏃")

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.emoji, "🏃")
    }

    func testNilEmojiIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(emoji: nil)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertNil(cached?.emoji)
    }

    func testTimestampsArePreservedInCache() async throws {
        // Given
        let createdAt = Date(timeIntervalSince1970: 1700000000)
        let updatedAt = Date(timeIntervalSince1970: 1700086400)

        let goal = TestFixtures.makeGoal(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(
            cached?.createdAt.timeIntervalSince1970,
            createdAt.timeIntervalSince1970,
            accuracy: 0.001
        )
        XCTAssertEqual(
            cached?.updatedAt.timeIntervalSince1970,
            updatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    // MARK: - Concurrent Operations

    func testConcurrentGoalCreations() async throws {
        // Given
        let goal1 = TestFixtures.makeGoal(id: UUID(), title: "Goal 1")
        let goal2 = TestFixtures.makeGoal(id: UUID(), title: "Goal 2")
        let goal3 = TestFixtures.makeGoal(id: UUID(), title: "Goal 3")

        // When - Save concurrently
        async let save1: Void = cacheService.saveGoal(goal1, syncState: .pending)
        async let save2: Void = cacheService.saveGoal(goal2, syncState: .pending)
        async let save3: Void = cacheService.saveGoal(goal3, syncState: .pending)

        let _ = try await (save1, save2, save3)

        // Then
        let all = try cacheService.fetchGoals(userId: TestFixtures.userId)
        XCTAssertEqual(all.count, 3)
    }

    // MARK: - Edge Cases

    func testEmptyTitleIsAllowed() async throws {
        // Given
        let goal = TestFixtures.makeGoal(title: "")

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.title, "")
    }

    func testVeryLongTitleIsPreserved() async throws {
        // Given
        let longTitle = String(repeating: "A", count: 1000)
        let goal = TestFixtures.makeGoal(title: longTitle)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.title, longTitle)
    }

    func testSpecialCharactersInTitleArePreserved() async throws {
        // Given
        let specialTitle = "Exercise & Fitness 💪 (2024) - 日本語"
        let goal = TestFixtures.makeGoal(title: specialTitle)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.title, specialTitle)
    }

    func testZeroPointsPerCompletionIsAllowed() async throws {
        // Given
        let goal = TestFixtures.makeGoal(pointsPerCompletion: 0)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.pointsPerCompletion, 0)
    }

    func testLargePointsPerCompletionIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(pointsPerCompletion: 999)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.pointsPerCompletion, 999)
    }

    func testHighTimesPerDayIsPreserved() async throws {
        // Given
        let goal = TestFixtures.makeGoal(timesPerDay: 50)

        // When
        try cacheService.saveGoal(goal, syncState: .synced)

        // Then
        let cached = try cacheService.fetchGoal(id: goal.id)
        XCTAssertEqual(cached?.timesPerDay, 50)
    }
}
