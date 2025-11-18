import Foundation
import Supabase
@testable import HabitTracker

/// Mock Supabase client for testing
final class MockSupabaseClient: @unchecked Sendable {
    // Response storage
    var selectResponse: Any?
    var insertResponse: Any?
    var updateResponse: Any?
    var deleteResponse: Any?
    var rpcResponse: Any?
    var shouldThrowError: Error?

    // Call tracking
    var selectCalled = false
    var insertCalled = false
    var updateCalled = false
    var deleteCalled = false
    var rpcCalled = false
    var lastTableName: String?
    var lastRpcName: String?
    var lastRpcParams: [String: Any]?

    // Auth mock
    let mockAuth = MockAuth()

    init() {}

    // Reset between tests
    func reset() {
        selectResponse = nil
        insertResponse = nil
        updateResponse = nil
        deleteResponse = nil
        rpcResponse = nil
        shouldThrowError = nil
        selectCalled = false
        insertCalled = false
        updateCalled = false
        deleteCalled = false
        rpcCalled = false
        lastTableName = nil
        lastRpcName = nil
        lastRpcParams = nil
    }
}

// Mock Auth
final class MockAuth: @unchecked Sendable {
    var mockUser: User?

    var currentUser: User? {
        get async { mockUser }
    }

    init() {
        // Default test user
        mockUser = User(
            id: TestFixtures.userId,
            appMetadata: [:],
            userMetadata: [:],
            aud: "test",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
