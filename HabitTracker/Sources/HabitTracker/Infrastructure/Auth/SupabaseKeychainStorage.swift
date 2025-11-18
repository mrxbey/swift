import Foundation
@preconcurrency import Auth

/// Adapter that makes KeychainStorage compatible with Supabase's AuthStorage protocol.
///
/// This class bridges our secure KeychainStorage implementation with the storage
/// interface expected by the Supabase Auth client. It ensures all session tokens
/// and auth data are stored securely in the iOS Keychain instead of UserDefaults.
///
/// Usage:
/// ```swift
/// let storage = SupabaseKeychainStorage()
/// SupabaseClient(
///     supabaseURL: url,
///     supabaseKey: key,
///     options: SupabaseClientOptions(
///         auth: .init(storage: storage)
///     )
/// )
/// ```
public final class SupabaseKeychainStorage: @unchecked Sendable, AuthStorage {
    // MARK: - Properties

    /// Underlying keychain storage implementation
    private let keychain: KeychainStorage

    // MARK: - Initialization

    /// Creates a new Supabase-compatible keychain storage
    ///
    /// - Parameter keychain: Underlying KeychainStorage instance. Creates default if not provided.
    public init(keychain: KeychainStorage = KeychainStorage()) {
        self.keychain = keychain
    }

    // MARK: - AuthStorage Protocol

    /// Stores a value for the given key
    ///
    /// - Parameters:
    ///   - key: Storage key
    ///   - value: Data to store
    public func store(key: String, value: Data) async throws {
        try keychain.store(key: key, value: value)
    }

    /// Retrieves the value for the given key
    ///
    /// - Parameter key: Storage key
    /// - Returns: Stored data, or nil if not found
    public func retrieve(key: String) async throws -> Data? {
        try keychain.retrieve(key: key)
    }

    /// Removes the value for the given key
    ///
    /// - Parameter key: Storage key to remove
    public func remove(key: String) async throws {
        try keychain.delete(key: key)
    }
}
