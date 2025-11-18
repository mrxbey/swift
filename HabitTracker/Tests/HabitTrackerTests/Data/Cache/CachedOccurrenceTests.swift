import XCTest
import SwiftData
@testable import HabitTracker

final class CachedOccurrenceTests: XCTestCase {

    // MARK: - Domain to Cache Conversion

    func testInitFromDomain() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 3,
            completedCount: 1,
            status: .pending
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertEqual(cached.id, occurrence.id)
        XCTAssertEqual(cached.userId, occurrence.userId)
        XCTAssertEqual(cached.goalId, occurrence.goalId)
        XCTAssertEqual(cached.targetCount, 3)
        XCTAssertEqual(cached.completedCount, 1)
        XCTAssertEqual(cached.status, "pending")
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithPendingState() {
        // Given
        let occurrence = TestFixtures.makeOccurrence()

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testInitFromDomainWithContentSnapshot() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Morning Run",
            emoji: "🏃",
            points: 15
        )
        let occurrence = TestFixtures.makeOccurrence(
            contentSnapshot: snapshot
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertEqual(cached.contentSnapshotTitle, "Morning Run")
        XCTAssertEqual(cached.contentSnapshotEmoji, "🏃")
        XCTAssertEqual(cached.contentSnapshotPoints, 15)
    }

    func testInitFromDomainWithoutContentSnapshot() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            contentSnapshot: nil
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertNil(cached.contentSnapshotTitle)
        XCTAssertNil(cached.contentSnapshotEmoji)
        XCTAssertEqual(cached.contentSnapshotPoints, 5) // Default value
    }

    func testInitFromDomainWithOverrides() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            nameOverride: "Custom Name",
            emojiOverride: "⭐"
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertEqual(cached.nameOverride, "Custom Name")
        XCTAssertEqual(cached.emojiOverride, "⭐")
    }

    func testInitFromDomainWithRollover() {
        // Given
        let rolledFromId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            keepUntilComplete: true,
            rolledFromId: rolledFromId
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertTrue(cached.keepUntilComplete)
        XCTAssertEqual(cached.rolledFromId, rolledFromId)
    }

    // MARK: - Cache to Domain Conversion

    func testToDomain() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 5,
            completedCount: 3,
            status: .pending
        )
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.id, occurrence.id)
        XCTAssertEqual(converted.userId, occurrence.userId)
        XCTAssertEqual(converted.goalId, occurrence.goalId)
        XCTAssertEqual(converted.targetCount, 5)
        XCTAssertEqual(converted.completedCount, 3)
        XCTAssertEqual(converted.status, .pending)
    }

    func testToDomainWithContentSnapshot() {
        // Given
        let snapshot = ContentSnapshot(title: "Test Task", emoji: "✅", points: 10)
        let occurrence = TestFixtures.makeOccurrence(contentSnapshot: snapshot)
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertNotNil(converted.contentSnapshot)
        XCTAssertEqual(converted.contentSnapshot?.title, "Test Task")
        XCTAssertEqual(converted.contentSnapshot?.emoji, "✅")
        XCTAssertEqual(converted.contentSnapshot?.points, 10)
    }

    func testToDomainWithoutContentSnapshot() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(contentSnapshot: nil)
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // When
        let converted = cached.toDomain()

        // Then
        XCTAssertNil(converted.contentSnapshot)
    }

    func testToDomainWithUnknownStatusDefaultsToPending() {
        // Given
        let cached = CachedOccurrence(
            id: TestFixtures.occurrenceId,
            userId: TestFixtures.userId,
            goalId: TestFixtures.goalId,
            scheduledDate: Date(),
            status: "unknown_status",
            targetCount: 1,
            completedCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let occurrence = cached.toDomain()

        // Then
        XCTAssertEqual(occurrence.status, .pending)
    }

    // MARK: - OccurrenceStatus Conversion

    func testStatusPendingConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .pending)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .pending)
    }

    func testStatusCompletedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .completed)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .completed)
    }

    func testStatusSkippedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .skipped)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .skipped)
    }

    func testStatusMissedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .missed)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .missed)
    }

    func testStatusCancelledConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .cancelled)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.status, .cancelled)
    }

    // MARK: - Update Method

    func testUpdateFromDomain() {
        // Given
        let originalOccurrence = TestFixtures.makeOccurrence(completedCount: 0)
        let cached = CachedOccurrence(from: originalOccurrence, syncState: .synced)

        let updatedOccurrence = TestFixtures.makeOccurrence(
            id: originalOccurrence.id,
            completedCount: 2,
            status: .pending,
            updatedAt: TestFixtures.laterDate
        )

        // When
        cached.update(from: updatedOccurrence, syncState: .pending)

        // Then
        XCTAssertEqual(cached.completedCount, 2)
        XCTAssertEqual(cached.status, "pending")
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertEqual(
            cached.updatedAt.timeIntervalSince1970,
            TestFixtures.laterDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testUpdateContentSnapshot() {
        // Given
        let originalSnapshot = ContentSnapshot(title: "Original", emoji: "🎯", points: 10)
        let originalOccurrence = TestFixtures.makeOccurrence(contentSnapshot: originalSnapshot)
        let cached = CachedOccurrence(from: originalOccurrence, syncState: .synced)

        let updatedSnapshot = ContentSnapshot(title: "Updated", emoji: "⭐", points: 20)
        let updatedOccurrence = TestFixtures.makeOccurrence(
            id: originalOccurrence.id,
            contentSnapshot: updatedSnapshot
        )

        // When
        cached.update(from: updatedOccurrence, syncState: .pending)

        // Then
        XCTAssertEqual(cached.contentSnapshotTitle, "Updated")
        XCTAssertEqual(cached.contentSnapshotEmoji, "⭐")
        XCTAssertEqual(cached.contentSnapshotPoints, 20)
    }

    func testUpdatePreservesSyncMetadata() {
        // Given
        let occurrence = TestFixtures.makeOccurrence()
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let originalSyncDate = cached.lastSyncedAt

        let updatedOccurrence = TestFixtures.makeOccurrence(
            id: occurrence.id,
            completedCount: 1
        )

        // When
        cached.update(from: updatedOccurrence, syncState: .synced)

        // Then
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
        let occurrence = TestFixtures.makeOccurrence()

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)

        // Then
        XCTAssertEqual(cached.syncState, "synced")
        XCTAssertNotNil(cached.lastSyncedAt)
    }

    func testSyncStatePending() {
        // Given
        let occurrence = TestFixtures.makeOccurrence()

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .pending)

        // Then
        XCTAssertEqual(cached.syncState, "pending")
        XCTAssertNil(cached.lastSyncedAt)
    }

    func testSyncStateFailed() {
        // Given
        let occurrence = TestFixtures.makeOccurrence()

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .failed)

        // Then
        XCTAssertEqual(cached.syncState, "failed")
        XCTAssertNil(cached.lastSyncedAt)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalOccurrence = TestFixtures.makeOccurrence(
            targetCount: 8,
            completedCount: 5,
            status: .pending,
            keepUntilComplete: true,
            nameOverride: "Custom Task",
            emojiOverride: "🎯",
            contentSnapshot: ContentSnapshot(title: "Original", emoji: "📝", points: 15),
            isOneTime: true
        )

        // When
        let cached = CachedOccurrence(from: originalOccurrence, syncState: .synced)
        let convertedOccurrence = cached.toDomain()

        // Then
        XCTAssertEqual(convertedOccurrence.id, originalOccurrence.id)
        XCTAssertEqual(convertedOccurrence.userId, originalOccurrence.userId)
        XCTAssertEqual(convertedOccurrence.goalId, originalOccurrence.goalId)
        XCTAssertEqual(convertedOccurrence.targetCount, originalOccurrence.targetCount)
        XCTAssertEqual(convertedOccurrence.completedCount, originalOccurrence.completedCount)
        XCTAssertEqual(convertedOccurrence.status, originalOccurrence.status)
        XCTAssertEqual(convertedOccurrence.keepUntilComplete, originalOccurrence.keepUntilComplete)
        XCTAssertEqual(convertedOccurrence.nameOverride, originalOccurrence.nameOverride)
        XCTAssertEqual(convertedOccurrence.emojiOverride, originalOccurrence.emojiOverride)
        XCTAssertEqual(convertedOccurrence.contentSnapshot?.title, originalOccurrence.contentSnapshot?.title)
        XCTAssertEqual(convertedOccurrence.isOneTime, originalOccurrence.isOneTime)
    }

    // MARK: - Edge Cases

    func testNilOptionalFields() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            dueAt: nil,
            nameOverride: nil,
            emojiOverride: nil,
            contentSnapshot: nil
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertNil(converted.dueAt)
        XCTAssertNil(converted.nameOverride)
        XCTAssertNil(converted.emojiOverride)
        XCTAssertNil(converted.contentSnapshot)
    }

    func testZeroCompletedCount() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(completedCount: 0)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.completedCount, 0)
    }

    func testHighTargetAndCompletedCounts() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 100,
            completedCount: 75
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.targetCount, 100)
        XCTAssertEqual(converted.completedCount, 75)
    }

    func testRolloverIds() {
        // Given
        let rolledFromId = UUID()
        let rolledIntoId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            rolledFromId: rolledFromId,
            rolledIntoId: rolledIntoId
        )

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertEqual(converted.rolledFromId, rolledFromId)
        XCTAssertEqual(converted.rolledIntoId, rolledIntoId)
    }

    func testDueAtDatePreservation() {
        // Given
        let dueDate = Date().addingTimeInterval(3600) // 1 hour from now
        let occurrence = TestFixtures.makeOccurrence(dueAt: dueDate)

        // When
        let cached = CachedOccurrence(from: occurrence, syncState: .synced)
        let converted = cached.toDomain()

        // Then
        XCTAssertNotNil(converted.dueAt)
        XCTAssertEqual(
            converted.dueAt?.timeIntervalSince1970,
            dueDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testKeepUntilCompleteFlags() {
        // Test both true and false
        for keepUntilComplete in [true, false] {
            // Given
            let occurrence = TestFixtures.makeOccurrence(keepUntilComplete: keepUntilComplete)

            // When
            let cached = CachedOccurrence(from: occurrence, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.keepUntilComplete, keepUntilComplete)
        }
    }

    func testIsOneTimeFlags() {
        // Test both true and false
        for isOneTime in [true, false] {
            // Given
            let occurrence = TestFixtures.makeOccurrence(isOneTime: isOneTime)

            // When
            let cached = CachedOccurrence(from: occurrence, syncState: .synced)
            let converted = cached.toDomain()

            // Then
            XCTAssertEqual(converted.isOneTime, isOneTime)
        }
    }
}
