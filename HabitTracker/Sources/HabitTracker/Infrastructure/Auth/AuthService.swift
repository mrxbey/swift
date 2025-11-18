import Foundation
import Supabase
import AuthenticationServices

/// Service for managing authentication with Supabase
///
/// Provides methods for sign in, sign up, sign out, and session management.
/// All methods are thread-safe and handle errors appropriately.
public actor AuthService {
    private let client: SupabaseClient

    /// MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    /// MARK: - Session Management

    /// Returns the current authenticated user
    ///
    /// - Returns: The current User or nil if not authenticated
    public func currentUser() async -> User? {
        await client.auth.currentUser
    }

    /// Returns the current session
    ///
    /// - Returns: The current Session or nil if not authenticated
    public func currentSession() async -> Session? {
        await client.auth.currentSession
    }

    /// Checks if a user is currently authenticated
    ///
    /// - Returns: true if user is authenticated
    public func isAuthenticated() async -> Bool {
        await currentUser() != nil
    }

    /// MARK: - Email Authentication

    /// Signs up a new user with email and password
    ///
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (minimum 6 characters)
    /// - Returns: The authenticated session
    /// - Throws: AuthError if sign up fails
    public func signUpWithEmail(email: String, password: String) async throws -> Session {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )

            guard let session = response.session else {
                throw AuthError.noSession
            }

            return session
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    /// Signs in an existing user with email and password
    ///
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated session
    /// - Throws: AuthError if sign in fails
    public func signInWithEmail(email: String, password: String) async throws -> Session {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            return session
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    /// Sends a password reset email
    ///
    /// - Parameter email: User's email address
    /// - Throws: AuthError if request fails
    public func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw AuthError.resetPasswordFailed(error.localizedDescription)
        }
    }

    /// Updates the user's password
    ///
    /// - Parameter newPassword: The new password
    /// - Throws: AuthError if update fails
    public func updatePassword(newPassword: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw AuthError.updatePasswordFailed(error.localizedDescription)
        }
    }

    /// MARK: - Sign in with Apple

    /// Signs in with Apple using an authorization credential
    ///
    /// - Parameter credential: The ASAuthorizationAppleIDCredential from Sign in with Apple
    /// - Returns: The authenticated session
    /// - Throws: AuthError if sign in fails
    public func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> Session {
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidAppleCredential
        }

        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )

            // Create or update profile if this is first sign in
            if let user = session.user {
                try await ensureProfileExists(for: user, appleCredential: credential)
            }

            return session
        } catch {
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }

    /// MARK: - Sign Out

    /// Signs out the current user
    ///
    /// - Throws: AuthError if sign out fails
    public func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    /// MARK: - Session Refresh

    /// Refreshes the current session
    ///
    /// - Returns: The refreshed session
    /// - Throws: AuthError if refresh fails
    public func refreshSession() async throws -> Session {
        do {
            let session = try await client.auth.session
            return session
        } catch {
            throw AuthError.sessionRefreshFailed(error.localizedDescription)
        }
    }

    /// MARK: - Profile Management

    /// Ensures a profile exists for the user
    ///
    /// Creates a profile if it doesn't exist, using data from Apple credential if available.
    ///
    /// - Parameters:
    ///   - user: The authenticated user
    ///   - appleCredential: Optional Apple credential for initial profile data
    private func ensureProfileExists(
        for user: User,
        appleCredential: ASAuthorizationAppleIDCredential? = nil
    ) async throws {
        // Check if profile already exists
        let existingProfile: ProfileDTO? = try? await client
            .from("profiles")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value

        if existingProfile != nil {
            // Profile exists, nothing to do
            return
        }

        // Create new profile
        var displayName: String?
        if let credential = appleCredential,
           let fullName = credential.fullName {
            let firstName = fullName.givenName ?? ""
            let lastName = fullName.familyName ?? ""
            displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            if displayName?.isEmpty == true {
                displayName = nil
            }
        }

        let profile = Profile(
            id: user.id,
            displayName: displayName,
            avatarURL: nil,
            timezone: TimeZone.current.identifier,
            weekStartsOn: 1, // Monday
            dailyReminderEnabled: false,
            dailyReminderTime: nil,
            totalPoints: 0,
            currentStreak: 0,
            longestStreak: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = ProfileDTO(from: profile)

        try await client
            .from("profiles")
            .insert(dto)
            .execute()
    }

    /// MARK: - Email Verification

    /// Checks if the current user's email is verified
    ///
    /// - Returns: true if email is verified
    public func isEmailVerified() async -> Bool {
        guard let user = await currentUser() else {
            return false
        }

        return user.emailConfirmedAt != nil
    }

    /// Resends the verification email
    ///
    /// - Throws: AuthError if request fails
    public func resendVerificationEmail() async throws {
        guard let user = await currentUser(),
              let email = user.email else {
            throw AuthError.noUserSession
        }

        do {
            try await client.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            throw AuthError.resendVerificationFailed(error.localizedDescription)
        }
    }
}

/// MARK: - AuthError

/// Authentication-related errors
public enum AuthError: LocalizedError, Equatable, Sendable {
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case resetPasswordFailed(String)
    case updatePasswordFailed(String)
    case sessionRefreshFailed(String)
    case appleSignInFailed(String)
    case invalidAppleCredential
    case noSession
    case noUserSession
    case resendVerificationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .resetPasswordFailed(let message):
            return "Password reset failed: \(message)"
        case .updatePasswordFailed(let message):
            return "Password update failed: \(message)"
        case .sessionRefreshFailed(let message):
            return "Session refresh failed: \(message)"
        case .appleSignInFailed(let message):
            return "Sign in with Apple failed: \(message)"
        case .invalidAppleCredential:
            return "Invalid Apple credential"
        case .noSession:
            return "No session was returned"
        case .noUserSession:
            return "No active user session"
        case .resendVerificationFailed(let message):
            return "Resend verification failed: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .signUpFailed:
            return "Check your email and password, then try again"
        case .signInFailed:
            return "Verify your credentials and try again"
        case .signOutFailed:
            return "Try again in a moment"
        case .resetPasswordFailed:
            return "Check your email address and try again"
        case .updatePasswordFailed:
            return "Ensure your new password meets requirements"
        case .sessionRefreshFailed:
            return "Try signing in again"
        case .appleSignInFailed:
            return "Try again or use email authentication"
        case .invalidAppleCredential:
            return "Try signing in with Apple again"
        case .noSession:
            return "Try signing in again"
        case .noUserSession:
            return "Sign in to continue"
        case .resendVerificationFailed:
            return "Wait a moment and try again"
        }
    }
}
