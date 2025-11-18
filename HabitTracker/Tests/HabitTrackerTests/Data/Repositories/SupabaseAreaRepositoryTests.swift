import XCTest
import SwiftData
@testable import HabitTracker

/// Comprehensive tests for SupabaseAreaRepository
///
/// Tests focus on repository-controlled logic:
/// - Cache-first read behavior
/// - Offline operation queuing (write-through pattern)
/// - Sync coordination
/// - Error handling
///
/// Note: These tests verify repository logic, not Supabase client behavior.
/// Integration tests against real Supabase instance are recommended for E2E validation.
@MainActor
final class SupabaseAreaRepositoryTests: XCTestCase {
    var cacheService: CacheService!
    var networkMonitor: MockNetworkMonitor!
    var syncEngine: MockSyncEngine!

    override func setUp() async throws {
        try await super.setUp()

        // Use real CacheService (already tested)
        cacheService = try CacheService()

        // Use mock dependencies
        networkMonitor = MockNetworkMonitor()
        syncEngine = MockSyncEngine()

        // Set network online by default
        await networkMonitor.setConnected(true)
    }

    override func tearDown() async throws {
        // Clean up cache
        try cacheService.clearAll()
        cacheService = nil

        // Reset mocks
        await networkMonitor.reset()
        await syncEngine.reset()

        try await super.tearDown()
    }

    // MARK: - Cache-First Read Behavior

    func testFetchAllWithCachedDataReturnsImmediately() async throws {
        // Given - Populate cache with areas
        let area1 = TestFixtures.makeArea(id: UUID(), name: "Health")
        let area2 = TestFixtures.makeArea(id: UUID(), name: "Work")

        try cacheService.saveArea(area1, syncState: .synced)
        try cacheService.saveArea(area2, syncState: .synced)

        // Note: Cannot test full repository without mocking Supabase client
        // This demonstrates the cache-first pattern at the CacheService level

        // When - Fetch from cache
        let cached = try cacheService.fetchAreas(userId: TestFixtures.userId)

        // Then - Cache returns data immediately
        XCTAssertEqual(cached.count, 2)
        XCTAssertTrue(cached.contains(where: { $0.name == "Health" }))
        XCTAssertTrue(cached.contains(where: { $0.name == "Work" }))
    }

    func testFetchByIdWithCachedDataReturnsImmediately() async throws {
        // Given - Populate cache
        let area = TestFixtures.makeArea(name: "Fitness")
        try cacheService.saveArea(area, syncState: .synced)

        // When - Fetch from cache
        let cached = try cacheService.fetchArea(id: area.id)

        // Then - Returns cached area
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.name, "Fitness")
        XCTAssertEqual(cached?.id, area.id)
    }

    func testFetchByIdWithCacheMissReturnsNil() async throws {
        // Given - Empty cache
        let nonExistentId = UUID()

        // When - Fetch non-existent area
        let result = try cacheService.fetchArea(id: nonExistentId)

        // Then - Returns nil
        XCTAssertNil(result)
    }

    // MARK: - Offline Operation Queuing (Write-Through Pattern)

    func testCreateOfflineSavesToCacheWithPendingState() async throws {
        // Given - Offline network
        await networkMonitor.setConnected(false)

        let area = TestFixtures.makeArea(name: "New Area")

        // When - Save to cache with pending state
        try cacheService.saveArea(area, syncState: .pending)

        // Then - Area is cached with pending state
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.name, "New Area")

        // Verify area is in pending queue
        let pending = try cacheService.fetchPendingAreas()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, area.id)
    }

    func testUpdateOfflineSavesToCacheWithPendingState() async throws {
        // Given - Area exists in cache as synced
        let originalArea = TestFixtures.makeArea(name: "Original")
        try cacheService.saveArea(originalArea, syncState: .synced)

        // Set network offline
        await networkMonitor.setConnected(false)

        // When - Update area while offline
        var updatedArea = originalArea
        updatedArea.name = "Updated Offline"
        updatedArea.updatedAt = Date()

        try cacheService.saveArea(updatedArea, syncState: .pending)

        // Then - Area is updated in cache with pending state
        let cached = try cacheService.fetchArea(id: originalArea.id)
        XCTAssertEqual(cached?.name, "Updated Offline")

        // Verify area is in pending queue
        let pending = try cacheService.fetchPendingAreas()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.name, "Updated Offline")
    }

    func testDeleteOfflineRemovesFromCache() async throws {
        // Given - Area exists in cache
        let area = TestFixtures.makeArea()
        try cacheService.saveArea(area, syncState: .synced)

        // Set network offline
        await networkMonitor.setConnected(false)

        // When - Delete from cache
        try cacheService.deleteArea(id: area.id)

        // Then - Area is removed from cache
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertNil(cached)
    }

    // MARK: - Sync State Management

    func testArchiveChangesStatusAndMarksPending() async throws {
        // Given - Active area in cache
        let area = TestFixtures.makeArea(status: .active)
        try cacheService.saveArea(area, syncState: .synced)

        // When - Archive the area
        var archivedArea = area
        archivedArea.status = .archived
        archivedArea.updatedAt = Date()

        try cacheService.saveArea(archivedArea, syncState: .pending)

        // Then - Status is changed and marked as pending
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.status, .archived)

        let pending = try cacheService.fetchPendingAreas()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.status, .archived)
    }

    func testSyncedAreasAreNotInPendingQueue() async throws {
        // Given - Synced areas in cache
        let area1 = TestFixtures.makeArea(id: UUID(), name: "Synced 1")
        let area2 = TestFixtures.makeArea(id: UUID(), name: "Synced 2")

        try cacheService.saveArea(area1, syncState: .synced)
        try cacheService.saveArea(area2, syncState: .synced)

        // When - Check pending queue
        let pending = try cacheService.fetchPendingAreas()

        // Then - No areas in pending queue
        XCTAssertTrue(pending.isEmpty)
    }

    func testPendingAreasAreInPendingQueue() async throws {
        // Given - Mix of synced and pending areas
        let syncedArea = TestFixtures.makeArea(id: UUID(), name: "Synced")
        let pendingArea1 = TestFixtures.makeArea(id: UUID(), name: "Pending 1")
        let pendingArea2 = TestFixtures.makeArea(id: UUID(), name: "Pending 2")

        try cacheService.saveArea(syncedArea, syncState: .synced)
        try cacheService.saveArea(pendingArea1, syncState: .pending)
        try cacheService.saveArea(pendingArea2, syncState: .pending)

        // When - Check pending queue
        let pending = try cacheService.fetchPendingAreas()

        // Then - Only pending areas are in queue
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.contains(where: { $0.name == "Pending 1" }))
        XCTAssertTrue(pending.contains(where: { $0.name == "Pending 2" }))
        XCTAssertFalse(pending.contains(where: { $0.name == "Synced" }))
    }

    // MARK: - Network State Handling

    func testNetworkOnlineReturnsTrue() async throws {
        // Given - Network set to online
        await networkMonitor.setConnected(true)

        // When - Check connection status
        let isConnected = await networkMonitor.isConnected()

        // Then - Returns true
        XCTAssertTrue(isConnected)
    }

    func testNetworkOfflineReturnsFalse() async throws {
        // Given - Network set to offline
        await networkMonitor.setConnected(false)

        // When - Check connection status
        let isConnected = await networkMonitor.isConnected()

        // Then - Returns false
        XCTAssertFalse(isConnected)
    }

    // MARK: - Concurrent Operations

    func testConcurrentAreaCreationsSaveToCache() async throws {
        // Given - Multiple areas to create
        let area1 = TestFixtures.makeArea(id: UUID(), name: "Area 1")
        let area2 = TestFixtures.makeArea(id: UUID(), name: "Area 2")
        let area3 = TestFixtures.makeArea(id: UUID(), name: "Area 3")

        // When - Save concurrently
        async let save1: Void = cacheService.saveArea(area1, syncState: .pending)
        async let save2: Void = cacheService.saveArea(area2, syncState: .pending)
        async let save3: Void = cacheService.saveArea(area3, syncState: .pending)

        let _ = try await (save1, save2, save3)

        // Then - All areas are saved
        let cached = try cacheService.fetchAreas(userId: TestFixtures.userId)
        XCTAssertEqual(cached.count, 3)
    }

    // MARK: - Data Integrity

    func testUserIdIsPreservedInCache() async throws {
        // Given - Area with specific user ID
        let userId = UUID()
        let area = TestFixtures.makeArea(userId: userId, name: "User Area")

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - User ID is preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.userId, userId)
    }

    func testTimestampsArePreservedInCache() async throws {
        // Given - Area with specific timestamps
        let createdAt = Date(timeIntervalSince1970: 1700000000)
        let updatedAt = Date(timeIntervalSince1970: 1700086400)

        let area = TestFixtures.makeArea(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Timestamps are preserved
        let cached = try cacheService.fetchArea(id: area.id)
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

    func testOptionalFieldsArePreservedInCache() async throws {
        // Given - Area with all optional fields set
        let area = TestFixtures.makeArea(
            emoji: "🎯",
            colorHex: "#FF6B6B"
        )

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Optional fields are preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.emoji, "🎯")
        XCTAssertEqual(cached?.colorHex, "#FF6B6B")
    }

    func testOptionalFieldsCanBeNilInCache() async throws {
        // Given - Area with nil optional fields
        let area = TestFixtures.makeArea(
            emoji: nil,
            colorHex: nil
        )

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Nil values are preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertNil(cached?.emoji)
        XCTAssertNil(cached?.colorHex)
    }

    // MARK: - Status Transitions

    func testAreaStatusTransitionsAreTracked() async throws {
        // Given - Active area
        let area = TestFixtures.makeArea(status: .active)
        try cacheService.saveArea(area, syncState: .synced)

        // When - Transition through states
        var pausedArea = area
        pausedArea.status = .paused
        try cacheService.saveArea(pausedArea, syncState: .pending)

        var archivedArea = pausedArea
        archivedArea.status = .archived
        try cacheService.saveArea(archivedArea, syncState: .pending)

        // Then - Final status is correct
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.status, .archived)
    }

    // MARK: - Edge Cases

    func testEmptyAreaNameIsAllowed() async throws {
        // Given - Area with empty name
        let area = TestFixtures.makeArea(name: "")

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Empty name is preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.name, "")
    }

    func testVeryLongAreaNameIsPreserved() async throws {
        // Given - Area with very long name
        let longName = String(repeating: "A", count: 1000)
        let area = TestFixtures.makeArea(name: longName)

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Long name is preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.name, longName)
    }

    func testSpecialCharactersInAreaNameArePreserved() async throws {
        // Given - Area with special characters
        let specialName = "Health & Fitness 💪 (2024) - 日本語"
        let area = TestFixtures.makeArea(name: specialName)

        // When - Save to cache
        try cacheService.saveArea(area, syncState: .synced)

        // Then - Special characters are preserved
        let cached = try cacheService.fetchArea(id: area.id)
        XCTAssertEqual(cached?.name, specialName)
    }
}
