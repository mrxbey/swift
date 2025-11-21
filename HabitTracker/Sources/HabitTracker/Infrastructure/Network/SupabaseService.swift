import Foundation
import Supabase

/// Thread-safe singleton service for managing Supabase client connection.
///
/// This actor ensures all Supabase operations are performed safely across different tasks
/// and provides a centralized point for client configuration.
///
/// Usage:
/// ```swift
/// let service = await SupabaseService.shared
/// let client = await service.getClient()
/// ```
public actor SupabaseService: Sendable {
    /// Shared singleton instance
    public static let shared = SupabaseService()

    /// The underlying Supabase client (lazily initialized)
    private var client: SupabaseClient?

    /// Private initializer to enforce singleton pattern
    private init() {
        // Client will be initialized lazily on first access
    }

    /// Creates and returns a configured Supabase client
    ///
    /// - Returns: The configured SupabaseClient
    /// - Throws: SupabaseError.configurationError if configuration is invalid
    /// - Throws: SupabaseError.invalidURL if the URL cannot be parsed
    private func createClient() throws -> SupabaseClient {
        // Validate configuration
        do {
            try Config.validate()
        } catch {
            throw SupabaseError.configurationError(error.localizedDescription)
        }

        // Parse URL
        guard let url = URL(string: Config.supabaseURL) else {
            throw SupabaseError.invalidURL(Config.supabaseURL)
        }

        // Initialize client with configuration
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(
                    schema: "public"
                ),
                auth: .init(
                    autoRefreshToken: true,
                    persistSession: true,
                    storage: SupabaseKeychainStorage(),
                    flowType: .pkce
                ),
                global: .init(
                    headers: [
                        "apikey": Config.supabaseAnonKey,
                        "X-Client-Info": "habittracker-ios/1.0.0"
                    ]
                )
            )
        )
    }

    /// Returns the configured Supabase client, creating it if necessary
    ///
    /// - Returns: The SupabaseClient instance for making API calls
    /// - Throws: SupabaseError.configurationError if configuration is invalid
    /// - Throws: SupabaseError.invalidURL if the URL cannot be parsed
    public func getClient() throws -> SupabaseClient {
        if let client = client {
            return client
        }

        let newClient = try createClient()
        self.client = newClient
        return newClient
    }

    /// Tests the connection to Supabase by querying the profiles table
    ///
    /// - Returns: `true` if connection is successful, `false` otherwise
    /// - Throws: SupabaseError if connection fails
    public func testConnection() async throws -> Bool {
        let client = try getClient()

        do {
            // Simple query to verify connection
            let _: [Profile] = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
                .value

            return true
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.networkError(error)
        }
    }

    /// Returns the current authenticated user, if any
    ///
    /// - Returns: The current User or nil if not authenticated
    /// - Throws: SupabaseError if client configuration fails
    public func currentUser() async throws -> User? {
        let client = try getClient()
        return await client.auth.currentUser
    }

    /// Returns the current session, if any
    ///
    /// - Returns: The current Session or nil if not authenticated
    /// - Throws: SupabaseError if client configuration fails
    public func currentSession() async throws -> Session? {
        let client = try getClient()
        return await client.auth.currentSession
    }
}

/// MARK: - Helper Types

/// Minimal Profile structure for connection testing
private struct Profile: Codable {
    let id: UUID
}
