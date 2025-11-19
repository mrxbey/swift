import ComposableArchitecture
import Foundation
import AuthenticationServices

/// Feature for user authentication
///
/// Handles sign in, sign up, and password reset flows.
@Reducer
public struct AuthenticationFeature {

    /// MARK: - State

    @ObservableState
    public struct State: Equatable {
        public enum Mode {
            case signIn
            case signUp
            case resetPassword
        }

        public var mode: Mode = .signIn
        public var email: String = ""
        public var password: String = ""
        public var confirmPassword: String = ""
        public var isLoading: Bool = false
        public var error: String?
        public var showResetPasswordSuccess: Bool = false

        // Validation
        public var isEmailValid: Bool {
            email.contains("@") && email.contains(".")
        }

        public var isPasswordValid: Bool {
            // Match server-side validation (AuthService.swift lines 220-236)
            guard password.count >= 8 else { return false }
            guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else { return false }
            guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else { return false }
            guard password.rangeOfCharacter(from: .decimalDigits) != nil else { return false }

            // Check common weak passwords
            let commonPasswords = ["password", "12345678", "qwerty123", "password1"]
            let lowercasePassword = password.lowercased()
            if commonPasswords.contains(lowercasePassword) {
                return false
            }

            return true
        }

        public var doPasswordsMatch: Bool {
            password == confirmPassword
        }

        public var canSubmit: Bool {
            guard isEmailValid else { return false }

            switch mode {
            case .signIn:
                return isPasswordValid

            case .signUp:
                return isPasswordValid && doPasswordsMatch

            case .resetPassword:
                return true
            }
        }

        public var submitButtonTitle: String {
            switch mode {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Sign Up"
            case .resetPassword:
                return "Send Reset Link"
            }
        }

        public init() {}
    }

    /// MARK: - Action

    public enum Action: Sendable {
        // User inputs
        case emailChanged(String)
        case passwordChanged(String)
        case confirmPasswordChanged(String)
        case modeChanged(State.Mode)

        // Auth actions
        case submitTapped
        case signInWithAppleTapped
        case signInWithAppleResponse(TaskResult<Session>)

        // Responses
        case authResponse(TaskResult<Session>)
        case resetPasswordResponse(TaskResult<Void>)

        // Delegate
        case delegate(Delegate)

        public enum Delegate: Sendable {
            case authenticationSucceeded(Session)
        }
    }

    /// MARK: - Dependencies

    @Dependency(\.authService) var authService
    @Dependency(\.continuousClock) var clock

    /// MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            /// MARK: User Inputs

            case let .emailChanged(email):
                state.email = email
                state.error = nil
                return .none

            case let .passwordChanged(password):
                state.password = password
                state.error = nil
                return .none

            case let .confirmPasswordChanged(confirmPassword):
                state.confirmPassword = confirmPassword
                state.error = nil
                return .none

            case let .modeChanged(mode):
                state.mode = mode
                state.error = nil
                state.showResetPasswordSuccess = false
                // Clear password fields when switching modes
                if mode != .signIn {
                    state.password = ""
                    state.confirmPassword = ""
                }
                return .none

            /// MARK: Auth Actions

            case .submitTapped:
                guard state.canSubmit else {
                    state.error = "Please check your inputs"
                    return .none
                }

                state.isLoading = true
                state.error = nil

                switch state.mode {
                case .signIn:
                    return .run { [email = state.email, password = state.password] send in
                        await send(.authResponse(
                            TaskResult {
                                try await authService.signInWithEmail(
                                    email: email,
                                    password: password
                                )
                            }
                        ))
                    }

                case .signUp:
                    return .run { [email = state.email, password = state.password] send in
                        await send(.authResponse(
                            TaskResult {
                                try await authService.signUpWithEmail(
                                    email: email,
                                    password: password
                                )
                            }
                        ))
                    }

                case .resetPassword:
                    return .run { [email = state.email] send in
                        await send(.resetPasswordResponse(
                            TaskResult {
                                try await authService.resetPassword(email: email)
                            }
                        ))
                    }
                }

            case .signInWithAppleTapped:
                state.isLoading = true
                state.error = nil

                // The actual Sign in with Apple flow is handled by the view
                // This action is here for completeness
                return .none

            case let .signInWithAppleResponse(result):
                state.isLoading = false

                switch result {
                case let .success(session):
                    return .send(.delegate(.authenticationSucceeded(session)))

                case let .failure(error):
                    if let authError = error as? AuthError {
                        state.error = authError.errorDescription
                    } else {
                        state.error = "Sign in with Apple failed: \(error.localizedDescription)"
                    }
                    return .none
                }

            /// MARK: Responses

            case let .authResponse(.success(session)):
                state.isLoading = false
                return .send(.delegate(.authenticationSucceeded(session)))

            case let .authResponse(.failure(error)):
                state.isLoading = false

                if let authError = error as? AuthError {
                    state.error = authError.errorDescription
                } else {
                    state.error = error.localizedDescription
                }
                return .none

            case .resetPasswordResponse(.success):
                state.isLoading = false
                state.showResetPasswordSuccess = true

                // Auto-dismiss success message after 3 seconds
                return .run { send in
                    try await clock.sleep(for: .seconds(3))
                    await send(.modeChanged(.signIn))
                }

            case let .resetPasswordResponse(.failure(error)):
                state.isLoading = false

                if let authError = error as? AuthError {
                    state.error = authError.errorDescription
                } else {
                    state.error = "Password reset failed: \(error.localizedDescription)"
                }
                return .none

            /// MARK: Delegate

            case .delegate:
                return .none
            }
        }
    }
}

/// MARK: - Dependency Key

extension DependencyValues {
    public var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

private enum AuthServiceKey: DependencyKey {
    static let liveValue: AuthService = AuthService()
    static let testValue: AuthService = AuthService()
    static let previewValue: AuthService = AuthService()
}
