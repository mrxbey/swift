import XCTest
import SwiftData
@testable import HabitTracker

final class CachedGoalTests: XCTestCase {

    // MARK: - Domain to Cache Conversion

    func testInitFromDomain() {
        // Given
        let goal = TestFixtures.makeGoal(
            title: "Morning Workout",
            emoji: "💪",
            kind: .habit,
            timesPerDay: 2,
            pointsPerCompletion: 15
        )

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)

        // Then
        XCTAssertEqual(cached.id, goal.id)
        XCTAssertEqual(cached.userId, goal.userId)
        XCTAssertEqual(cached.areaId, goal.areaId)
        XCTAssertEqual(cached.title, "Morning Workout")
        XCTAssertEqual(cached.emoji, "💪")
        XCTAssertEqual(cached.kind, "habit")
        XCTAssertEqual(cached.status, "active")
        XCTAssertEqual(cached.timesPerDay, 2)
        XCTAssertEqual(cached.pointsPerCompletion, 15)
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithPendingState() {
        // Given
        let goal = TestFixtures.makeGoal()

        // When
        let cached = CachedGoal(from: goal, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithHashtags() {
        // Given
        let goal = TestFixtures.makeGoal(hashtags: ["fitness", "morning", "health"])

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)

        // Then
        XCTAssertEqual(cached.hashtags, ["fitness", "morning", "health"])
    }

    func testInitFromDomainWithLinkedExercise() {
        // Given
        let goal = TestFixtures.makeGoal(linkedExerciseKey: .meditation)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)

        // Then
        XCTAssertEqual(cached.linkedExerciseKey, "meditation")
    }

    // MARK: - Cache to Domain Conversion

    func testToDomain() {
        // Given
        let goal = TestFixtures.makeGoal(
            title: "Read Daily",
            emoji: "📚",
            kind: .habit
        )
        let cached = CachedGoal(from: goal, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.id, goal.id)
        XCTAssertEqual(converted.userId, goal.userId)
        XCTAssertEqual(converted.areaId, goal.areaId)
        XCTAssertEqual(converted.title, "Read Daily")
        XCTAssertEqual(converted.emoji, "📚")
        XCTAssertEqual(converted.kind, .habit)
        XCTAssertEqual(converted.status, .active)
    }

    func testToDomainWithUnknownKindDefaultsToHabit() {
        // Given
        let cached = CachedGoal(
            id: TestFixtures.goalId,
            userId: TestFixtures.userId,
            areaId: TestFixtures.areaId,
            title: "Test",
            kind: "unknown_kind",
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let goal = cached.toDomain()

        // Then
        XCTAssertEqual(goal.kind, .habit)
    }

    func testToDomainWithUnknownStatusDefaultsToActive() {
        // Given
        let cached = CachedGoal(
            id: TestFixtures.goalId,
            userId: TestFixtures.userId,
            areaId: TestFixtures.areaId,
            title: "Test",
            kind: "habit",
            status: "unknown_status",
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let goal = cached.toDomain()

        // Then
        XCTAssertEqual(goal.status, .active)
    }

    // MARK: - GoalKind Conversion

    func testGoalKindHabitConversion() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .habit)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.kind, .habit)
    }

    func testGoalKindTaskConversion() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .task)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.kind, .task)
    }

    func testGoalKindMeasureConversion() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .measure)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.kind, .measure)
    }

    // MARK: - GoalStatus Conversion

    func testGoalStatusActiveConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .active)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .active)
    }

    func testGoalStatusArchivedConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .archived)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .archived)
    }

    func testGoalStatusDeletedConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .deleted)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .deleted)
    }

    // MARK: - Update Method

    func testUpdateFromDomain() {
        // Given
        let originalGoal = TestFixtures.makeGoal(title: "Original")
        let cached = CachedGoal(from: originalGoal, syncState: .synced)

        let updatedGoal = TestFixtures.makeGoal(
            id: originalGoal.id,
            title: "Updated",
            emoji: "🎯",
            timesPerDay: 3,
            updatedAt: TestFixtures.laterDate
        )

        // When
        cached.update(from: updatedGoal, syncState: .pending)

        // Then
        XCTAssertEqual(cached.title, "Updated")
        XCTAssertEqual(cached.emoji, "🎯")
        XCTAssertEqual(cached.timesPerDay, 3)
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertEqual(
            cached.updatedAt.timeIntervalSince1970,
            TestFixtures.laterDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testUpdatePreservesSyncMetadata() {
        // Given
        let goal = TestFixtures.makeGoal()
        let cached = CachedGoal(from: goal, syncState: .synced)
        let originalSyncDate = cached.lastSyncedAt

        let updatedGoal = TestFixtures.makeGoal(
            id: goal.id,
            title: "Updated"
        )

        // When
        cached.update(from: updatedGoal, syncState: .synced)

        // Then
        XCTAssertEqual(cached.title, "Updated")
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
        let goal = TestFixtures.makeGoal()

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)

        // Then
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testSyncStatePending() {
        // Given
        let goal = TestFixtures.makeGoal()

        // When
        let cached = CachedGoal(from: goal, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testSyncStateFailed() {
        // Given
        let goal = TestFixtures.makeGoal()

        // When
        let cached = CachedGoal(from: goal, syncState: .failed)

        // Then
        XCTAssertEqual(cached.syncState, "failed")
        XCTAssertNil(cached.lastSyncedAt)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalGoal = TestFixtures.makeGoal(
            title: "Complete Project",
            emoji: "🚀",
            kind: .task,
            status: .active,
            keepUntilComplete: true,
            timesPerDay: 5,
            pointsPerCompletion: 25,
            linkedExerciseKey: .pomodoro,
            hashtags: ["work", "important", "urgent"]
        )

        // When
        let cached = CachedGoal(from: originalGoal, syncState: .synced)
        let convertedGoal = cached.toDomain()

        // Then
        XCTAssertEqual(convertedGoal.id, originalGoal.id)
        XCTAssertEqual(convertedGoal.userId, originalGoal.userId)
        XCTAssertEqual(convertedGoal.areaId, originalGoal.areaId)
        XCTAssertEqual(convertedGoal.title, originalGoal.title)
        XCTAssertEqual(convertedGoal.emoji, originalGoal.emoji)
        XCTAssertEqual(convertedGoal.kind, originalGoal.kind)
        XCTAssertEqual(convertedGoal.status, originalGoal.status)
        XCTAssertEqual(convertedGoal.keepUntilComplete, originalGoal.keepUntilComplete)
        XCTAssertEqual(convertedGoal.timesPerDay, originalGoal.timesPerDay)
        XCTAssertEqual(convertedGoal.pointsPerCompletion, originalGoal.pointsPerCompletion)
        XCTAssertEqual(convertedGoal.linkedExerciseKey, originalGoal.linkedExerciseKey)
        XCTAssertEqual(convertedGoal.hashtags, originalGoal.hashtags)
    }

    // MARK: - Edge Cases

    func testNilOptionalFields() {
        // Given
        let goal = TestFixtures.makeGoal(
            emoji: nil,
            linkedExerciseKey: nil,
            hashtags: []
        )

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertNil(converted.emoji)
        XCTAssertNil(converted.linkedExerciseKey)
        XCTAssertEqual(converted.hashtags, [])
    }

    func testEmptyHashtags() {
        // Given
        let goal = TestFixtures.makeGoal(hashtags: [])

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.hashtags, [])
    }

    func testMultipleHashtags() {
        // Given
        let hashtags = ["health", "fitness", "morning", "routine", "2023"]
        let goal = TestFixtures.makeGoal(hashtags: hashtags)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.hashtags, hashtags)
    }

    func testKeepUntilCompleteTrue() {
        // Given
        let goal = TestFixtures.makeGoal(keepUntilComplete: true)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertTrue(converted.keepUntilComplete)
    }

    func testKeepUntilCompleteFalse() {
        // Given
        let goal = TestFixtures.makeGoal(keepUntilComplete: false)

        // When
        let cached = CachedGoal(from: goal, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertFalse(converted.keepUntilComplete)
    }

    func testTimesPerDayBoundaries() {
        // Test various timesPerDay values
        let values = [1, 5, 10, 50, 100]

        for value in values {
            // Given
            let goal = TestFixtures.makeGoal(timesPerDay: value)

            // When
            let cached = CachedGoal(from: goal, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.timesPerDay, value)
        }
    }

    func testPointsPerCompletionValues() {
        // Test various pointsPerCompletion values
        let values = [0, 5, 10, 50, 100, 1000]

        for value in values {
            // Given
            let goal = TestFixtures.makeGoal(pointsPerCompletion: value)

            // When
            let cached = CachedGoal(from: goal, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.pointsPerCompletion, value)
        }
    }

    func testAllLinkedExerciseKeys() {
        // Test all LinkedExercise enum cases
        let exercises: [LinkedExercise] = [.meditation, .pomodoro, .study, .breath, .water, .affirmations, .journal, .mood]

        for exercise in exercises {
            // Given
            let goal = TestFixtures.makeGoal(linkedExerciseKey: exercise)

            // When
            let cached = CachedGoal(from: goal, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.linkedExerciseKey, exercise)
        }
    }
}
