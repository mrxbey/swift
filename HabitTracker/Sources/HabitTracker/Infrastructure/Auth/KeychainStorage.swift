import Foundation
import Security

/// Secure storage implementation using the iOS Keychain for sensitive auth tokens.
///
/// This class provides a thread-safe wrapper around the iOS Keychain APIs,
/// designed specifically for storing Supabase authentication tokens securely.
/// Unlike UserDefaults, Keychain data is encrypted and protected by the system.
///
/// Usage:
/// ```swift
/// let storage = KeychainStorage()
/// try storage.store(key: "session_token", value: tokenData)
/// let token = try storage.retrieve(key: "session_token")
/// try storage.delete(key: "session_token")
/// ```
public final class KeychainStorage: @unchecked Sendable {
    // MARK: - Properties

    /// Service identifier for keychain items
    /// This groups all app's keychain items together
    private let service: String

    /// Access group for keychain sharing (optional)
    private let accessGroup: String?

    // MARK: - Initialization

    /// Creates a new KeychainStorage instance
    ///
    /// - Parameters:
    ///   - service: Service identifier for keychain items. Defaults to bundle identifier.
    ///   - accessGroup: Optional access group for keychain sharing between apps
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "com.habittracker",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Public Methods

    /// Stores data in the Keychain
    ///
    /// If an item with the same key already exists, it will be updated.
    ///
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - value: Data to store securely
    /// - Throws: KeychainError if storage fails
    public func store(key: String, value: Data) throws {
        // Try to update existing item first
        let updateQuery = buildQuery(for: key)
        let attributes: [String: Any] = [
            kSecValueData as String: value
        ]

        let updateStatus = SecItemUpdate(
            updateQuery as CFDictionary,
            attributes as CFDictionary
        )

        // If item doesn't exist, add it
        if updateStatus == errSecItemNotFound {
            var addQuery = buildQuery(for: key)
            addQuery[kSecValueData as String] = value

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

            guard addStatus == errSecSuccess else {
                throw KeychainError.unableToStore(
                    status: addStatus,
                    message: "Failed to add keychain item for key: \(key)"
                )
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unableToStore(
                status: updateStatus,
                message: "Failed to update keychain item for key: \(key)"
            )
        }
    }

    /// Retrieves data from the Keychain
    ///
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Retrieved data, or nil if not found
    /// - Throws: KeychainError if retrieval fails
    public func retrieve(key: String) throws -> Data? {
        var query = buildQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unableToRetrieve(
                status: status,
                message: "Failed to retrieve keychain item for key: \(key)"
            )
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData(
                message: "Keychain item is not Data for key: \(key)"
            )
        }

        return data
    }

    /// Deletes data from the Keychain
    ///
    /// - Parameter key: Unique identifier for the data to delete
    /// - Throws: KeychainError if deletion fails
    public func delete(key: String) throws {
        let query = buildQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        // Success if deleted or item didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(
                status: status,
                message: "Failed to delete keychain item for key: \(key)"
            )
        }
    }

    /// Deletes all items for this service from the Keychain
    ///
    /// Use with caution - this removes all stored auth data.
    ///
    /// - Throws: KeychainError if deletion fails
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Success if deleted or no items existed
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(
                status: status,
                message: "Failed to delete all keychain items for service: \(service)"
            )
        }
    }

    // MARK: - Private Methods

    /// Builds a base query dictionary for Keychain operations
    ///
    /// - Parameter key: Key to include in the query
    /// - Returns: Query dictionary for Keychain APIs
    private func buildQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - KeychainError

/// Errors that can occur during Keychain operations
public enum KeychainError: LocalizedError {
    case unableToStore(status: OSStatus, message: String)
    case unableToRetrieve(status: OSStatus, message: String)
    case unableToDelete(status: OSStatus, message: String)
    case unexpectedData(message: String)

    public var errorDescription: String? {
        switch self {
        case .unableToStore(let status, let message):
            return "Keychain storage error (status: \(status)): \(message)"
        case .unableToRetrieve(let status, let message):
            return "Keychain retrieval error (status: \(status)): \(message)"
        case .unableToDelete(let status, let message):
            return "Keychain deletion error (status: \(status)): \(message)"
        case .unexpectedData(let message):
            return "Keychain data error: \(message)"
        }
    }
}
