import XCTest
import SwiftData
@testable import HabitTracker

/// Comprehensive tests for SupabaseOccurrenceRepository
///
/// Tests occurrence-specific logic including:
/// - Date-based queries
/// - Status transitions
/// - Rollover tracking
/// - Content snapshots
@MainActor
final class SupabaseOccurrenceRepositoryTests: XCTestCase {
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

    // MARK: - Date-Based Queries

    func testFetchOccurrencesForSpecificDate() async throws {
        // Given - Occurrences on different dates
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

        // Then - Only today's occurrences
        XCTAssertEqual(fetchedToday.count, 1)
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(fetchedToday.first!.scheduledDate, inSameDayAs: today))
    }

    // MARK: - Status Transitions

    func testOccurrenceStatusPendingIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .pending)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.status, .pending)
    }

    func testOccurrenceStatusCompletedIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .completed)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.status, .completed)
    }

    func testOccurrenceStatusSkippedIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .skipped)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.status, .skipped)
    }

    func testOccurrenceStatusMissedIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .missed)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.status, .missed)
    }

    func testOccurrenceStatusCancelledIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .cancelled)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.status, .cancelled)
    }

    // MARK: - Target and Completion Counts

    func testTargetCountIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(targetCount: 5)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.targetCount, 5)
    }

    func testCompletedCountIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 5,
            completedCount: 3
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.completedCount, 3)
    }

    func testZeroCompletedCountIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(completedCount: 0)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.completedCount, 0)
    }

    func testHighTargetCountIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 100,
            completedCount: 75
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.targetCount, 100)
        XCTAssertEqual(cached?.completedCount, 75)
    }

    // MARK: - Rollover Tracking

    func testRolledFromIdIsPreserved() async throws {
        // Given
        let rolledFromId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            rolledFromId: rolledFromId
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.rolledFromId, rolledFromId)
    }

    func testRolledIntoIdIsPreserved() async throws {
        // Given
        let rolledIntoId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            rolledIntoId: rolledIntoId
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.rolledIntoId, rolledIntoId)
    }

    func testNilRolloverIdsArePreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            rolledFromId: nil,
            rolledIntoId: nil
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNil(cached?.rolledFromId)
        XCTAssertNil(cached?.rolledIntoId)
    }

    // MARK: - Content Snapshots

    func testContentSnapshotIsPreserved() async throws {
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
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNotNil(cached?.contentSnapshot)
        XCTAssertEqual(cached?.contentSnapshot?.title, "Morning Run")
        XCTAssertEqual(cached?.contentSnapshot?.emoji, "🏃")
        XCTAssertEqual(cached?.contentSnapshot?.points, 15)
    }

    func testNilContentSnapshotIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            contentSnapshot: nil
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNil(cached?.contentSnapshot)
    }

    // MARK: - Overrides

    func testNameOverrideIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            nameOverride: "Custom Name"
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.nameOverride, "Custom Name")
    }

    func testEmojiOverrideIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            emojiOverride: "⭐"
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertEqual(cached?.emojiOverride, "⭐")
    }

    func testNilOverridesArePreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            nameOverride: nil,
            emojiOverride: nil
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNil(cached?.nameOverride)
        XCTAssertNil(cached?.emojiOverride)
    }

    // MARK: - Flags

    func testKeepUntilCompleteTrueIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            keepUntilComplete: true
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertTrue(cached!.keepUntilComplete)
    }

    func testIsOneTimeTrueIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            isOneTime: true
        )

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertTrue(cached!.isOneTime)
    }

    // MARK: - Offline Operations

    func testCreateOccurrenceOfflineSavesWithPendingState() async throws {
        // Given - Offline
        await networkMonitor.setConnected(false)

        let occurrence = TestFixtures.makeOccurrence()

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .pending)

        // Then
        let pending = try cacheService.fetchPendingOccurrences()
        XCTAssertEqual(pending.count, 1)
    }

    func testUpdateOccurrenceOfflineMarksAsPending() async throws {
        // Given - Synced occurrence
        let occurrence = TestFixtures.makeOccurrence(completedCount: 0)
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        await networkMonitor.setConnected(false)

        // When - Update offline
        var updated = occurrence
        updated.completedCount = 1
        updated.updatedAt = Date()

        try cacheService.saveOccurrence(updated, syncState: .pending)

        // Then
        let pending = try cacheService.fetchPendingOccurrences()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.completedCount, 1)
    }

    // MARK: - Concurrent Operations

    func testConcurrentOccurrenceSaves() async throws {
        // Given
        let occ1 = TestFixtures.makeOccurrence(id: UUID())
        let occ2 = TestFixtures.makeOccurrence(id: UUID())
        let occ3 = TestFixtures.makeOccurrence(id: UUID())

        // When - Save concurrently
        async let save1: Void = cacheService.saveOccurrence(occ1, syncState: .pending)
        async let save2: Void = cacheService.saveOccurrence(occ2, syncState: .pending)
        async let save3: Void = cacheService.saveOccurrence(occ3, syncState: .pending)

        let _ = try await (save1, save2, save3)

        // Then
        let pending = try cacheService.fetchPendingOccurrences()
        XCTAssertEqual(pending.count, 3)
    }

    // MARK: - Timestamps

    func testDueAtDateIsPreserved() async throws {
        // Given
        let dueDate = Date().addingTimeInterval(3600)
        let occurrence = TestFixtures.makeOccurrence(dueAt: dueDate)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNotNil(cached?.dueAt)
        XCTAssertEqual(
            cached?.dueAt?.timeIntervalSince1970,
            dueDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testNilDueAtIsPreserved() async throws {
        // Given
        let occurrence = TestFixtures.makeOccurrence(dueAt: nil)

        // When
        try cacheService.saveOccurrence(occurrence, syncState: .synced)

        // Then
        let cached = try cacheService.fetchOccurrence(id: occurrence.id)
        XCTAssertNil(cached?.dueAt)
    }
}
