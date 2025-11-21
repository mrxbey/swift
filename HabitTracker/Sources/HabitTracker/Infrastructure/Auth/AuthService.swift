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

    /// Convenience initializer using shared Supabase service
    ///
    /// - Throws: SupabaseError if client configuration is invalid
    public init() async throws {
        self.client = try await SupabaseService.shared.getClient()
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
    ///   - password: User's password (minimum 8 characters with uppercase, lowercase, and digit)
    /// - Returns: The authenticated session
    /// - Throws: AuthError if sign up fails or validation fails
    public func signUpWithEmail(email: String, password: String) async throws -> Session {
        // Validate input before sending to server
        try validateEmail(email)
        try validatePassword(password)

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
    /// - Throws: AuthError if request fails or validation fails
    public func resetPassword(email: String) async throws {
        // Validate email format
        try validateEmail(email)

        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw AuthError.resetPasswordFailed(error.localizedDescription)
        }
    }

    /// Updates the user's password
    ///
    /// - Parameter newPassword: The new password (minimum 8 characters with uppercase, lowercase, and digit)
    /// - Throws: AuthError if update fails or validation fails
    public func updatePassword(newPassword: String) async throws {
        // Validate password strength
        try validatePassword(newPassword)

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

    /// Deletes the current user's account and all associated data
    ///
    /// This will:
    /// 1. Call the delete_user_account RPC function to remove all user data
    /// 2. Sign out the user
    ///
    /// - Throws: AuthError if deletion or sign out fails
    public func deleteAccount() async throws {
        guard await currentUser() != nil else {
            throw AuthError.noUserSession
        }

        do {
            // Call RPC function to delete all user data
            // The delete_user_account RPC should handle:
            // - Deleting measurements
            // - Deleting goal_occurrences
            // - Deleting goals
            // - Deleting reflections
            // - Deleting areas
            // - Deleting profile
            // Note: Auth account deletion may require admin API or separate handling
            try await client.rpc("delete_user_account").execute()

            // Sign out after successful deletion
            try await signOut()
        } catch {
            throw AuthError.accountDeletionFailed(error.localizedDescription)
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

    /// MARK: - Input Validation

    /// Validates email address format
    ///
    /// - Parameter email: Email address to validate
    /// - Throws: AuthError.invalidEmail if email format is invalid
    private func validateEmail(_ email: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            throw AuthError.invalidEmail("Email cannot be empty")
        }

        // RFC 5322 compliant email regex (simplified for common cases)
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)

        guard predicate.evaluate(with: trimmedEmail) else {
            throw AuthError.invalidEmail("Invalid email format")
        }
    }

    /// Validates password strength
    ///
    /// Requirements:
    /// - Minimum 8 characters
    /// - At least one uppercase letter
    /// - At least one lowercase letter
    /// - At least one digit
    ///
    /// - Parameter password: Password to validate
    /// - Throws: AuthError with specific validation failure
    private func validatePassword(_ password: String) throws {
        guard password.count >= 8 else {
            throw AuthError.passwordTooShort("Password must be at least 8 characters")
        }

        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
            throw AuthError.passwordNeedsUppercase("Password must contain at least one uppercase letter")
        }

        guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else {
            throw AuthError.passwordNeedsLowercase("Password must contain at least one lowercase letter")
        }

        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            throw AuthError.passwordNeedsNumber("Password must contain at least one number")
        }

        // Optional: Check for common weak passwords
        let commonPasswords = ["password", "12345678", "qwerty123", "password1"]
        let lowercasePassword = password.lowercased()
        if commonPasswords.contains(lowercasePassword) {
            throw AuthError.passwordTooWeak("This password is too common. Please choose a stronger password")
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
    case accountDeletionFailed(String)
    case invalidAppleCredential
    case noSession
    case noUserSession
    case resendVerificationFailed(String)

    // Input validation errors
    case invalidEmail(String)
    case passwordTooShort(String)
    case passwordNeedsUppercase(String)
    case passwordNeedsLowercase(String)
    case passwordNeedsNumber(String)
    case passwordTooWeak(String)

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
        case .accountDeletionFailed(let message):
            return "Account deletion failed: \(message)"
        case .invalidAppleCredential:
            return "Invalid Apple credential"
        case .noSession:
            return "No session was returned"
        case .noUserSession:
            return "No active user session"
        case .resendVerificationFailed(let message):
            return "Resend verification failed: \(message)"
        case .invalidEmail(let message):
            return message
        case .passwordTooShort(let message):
            return message
        case .passwordNeedsUppercase(let message):
            return message
        case .passwordNeedsLowercase(let message):
            return message
        case .passwordNeedsNumber(let message):
            return message
        case .passwordTooWeak(let message):
            return message
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
        case .accountDeletionFailed:
            return "Please try again. If the problem persists, contact support"
        case .invalidAppleCredential:
            return "Try signing in with Apple again"
        case .noSession:
            return "Try signing in again"
        case .noUserSession:
            return "Sign in to continue"
        case .resendVerificationFailed:
            return "Wait a moment and try again"
        case .invalidEmail:
            return "Enter a valid email address (e.g., user@example.com)"
        case .passwordTooShort:
            return "Use at least 8 characters for your password"
        case .passwordNeedsUppercase:
            return "Include at least one uppercase letter (A-Z)"
        case .passwordNeedsLowercase:
            return "Include at least one lowercase letter (a-z)"
        case .passwordNeedsNumber:
            return "Include at least one number (0-9)"
        case .passwordTooWeak:
            return "Choose a more unique password"
        }
    }
}
