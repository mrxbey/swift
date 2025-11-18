import Foundation
@testable import HabitTracker

/// Mock SyncEngine for testing repositories
///
/// Tracks sync calls without performing actual sync operations.
actor MockSyncEngine {
    // Call tracking
    var performFullSyncCalled = false
    var lastSyncedUserId: UUID?
    var syncCallCount = 0

    // Configuration
    var shouldThrowOnSync = false
    var syncError: Error?

    func performFullSync(userId: UUID) async throws {
        performFullSyncCalled = true
        lastSyncedUserId = userId
        syncCallCount += 1

        if shouldThrowOnSync, let error = syncError {
            throw error
        }
    }

    func reset() {
        performFullSyncCalled = false
        lastSyncedUserId = nil
        syncCallCount = 0
        shouldThrowOnSync = false
        syncError = nil
    }
}
