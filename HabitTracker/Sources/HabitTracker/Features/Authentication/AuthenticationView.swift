import SwiftUI
import ComposableArchitecture
import AuthenticationServices

/// View for user authentication
///
/// Supports Sign in with Apple, email sign in, and email sign up.
public struct AuthenticationView: View {
    @Bindable var store: StoreOf<AuthenticationFeature>
    @Environment(\.colorScheme) var colorScheme

    public init(store: StoreOf<AuthenticationFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection

                // Sign in with Apple
                if store.mode == .signIn || store.mode == .signUp {
                    signInWithAppleButton
                }

                // Divider
                if store.mode == .signIn || store.mode == .signUp {
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                }

                // Email form
                emailFormSection

                // Error message
                if let error = store.error {
                    errorBanner(error)
                }

                // Success message for password reset
                if store.showResetPasswordSuccess {
                    successBanner("Check your email for a password reset link")
                }

                // Submit button
                submitButton

                // Mode switcher
                modeSwitcher
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .background(backgroundColor)
    }

    /// MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("HabitTracker")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var headerSubtitle: String {
        switch store.mode {
        case .signIn:
            return "Sign in to continue tracking your habits"
        case .signUp:
            return "Create an account to start your journey"
        case .resetPassword:
            return "Enter your email to receive a reset link"
        }
    }

    /// MARK: - Sign in with Apple

    private var signInWithAppleButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                Task {
                    switch result {
                    case let .success(authorization):
                        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            await store.send(.signInWithAppleResponse(
                                TaskResult {
                                    try await store.authService.signInWithApple(credential: credential)
                                }
                            )).finish()
                        }

                    case let .failure(error):
                        await store.send(.signInWithAppleResponse(.failure(error))).finish()
                    }
                }
            }
        )
        .signInWithAppleButtonStyle(
            colorScheme == .dark ? .white : .black
        )
        .frame(height: 50)
        .cornerRadius(8)
    }

    /// MARK: - Email Form

    private var emailFormSection: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("you@example.com", text: $store.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .disabled(store.isLoading)
            }

            // Password field (not shown for reset password)
            if store.mode != .resetPassword {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    SecureField("••••••••", text: $store.password)
                        .textContentType(store.mode == .signUp ? .newPassword : .password)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .disabled(store.isLoading)

                    if store.mode == .signUp && !store.password.isEmpty && !store.isPasswordValid {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // Confirm password field (only for sign up)
            if store.mode == .signUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    SecureField("••••••••", text: $store.confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .disabled(store.isLoading)

                    if !store.confirmPassword.isEmpty && !store.doPasswordsMatch {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // Forgot password link
            if store.mode == .signIn {
                HStack {
                    Spacer()
                    Button {
                        store.send(.modeChanged(.resetPassword))
                    } label: {
                        Text("Forgot password?")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .disabled(store.isLoading)
                }
            }
        }
    }

    /// MARK: - Submit Button

    private var submitButton: some View {
        Button {
            store.send(.submitTapped)
        } label: {
            ZStack {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(store.submitButtonTitle)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(store.canSubmit ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!store.canSubmit || store.isLoading)
    }

    /// MARK: - Mode Switcher

    private var modeSwitcher: some View {
        VStack(spacing: 12) {
            if store.mode == .signIn {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button {
                        store.send(.modeChanged(.signUp))
                    } label: {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                    .disabled(store.isLoading)
                }
                .font(.subheadline)
            } else if store.mode == .signUp {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button {
                        store.send(.modeChanged(.signIn))
                    } label: {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .disabled(store.isLoading)
                }
                .font(.subheadline)
            } else if store.mode == .resetPassword {
                HStack(spacing: 4) {
                    Text("Remember your password?")
                        .foregroundStyle(.secondary)
                    Button {
                        store.send(.modeChanged(.signIn))
                    } label: {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .disabled(store.isLoading)
                }
                .font(.subheadline)
            }
        }
    }

    /// MARK: - Helpers

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private func successBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
}

/// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }
}

/// MARK: - Preview

#if DEBUG
#Preview("Sign In") {
    AuthenticationView(
        store: Store(
            initialState: AuthenticationFeature.State(mode: .signIn)
        ) {
            AuthenticationFeature()
        }
    )
}

#Preview("Sign Up") {
    AuthenticationView(
        store: Store(
            initialState: AuthenticationFeature.State(mode: .signUp)
        ) {
            AuthenticationFeature()
        }
    )
}

#Preview("Reset Password") {
    AuthenticationView(
        store: Store(
            initialState: AuthenticationFeature.State(mode: .resetPassword)
        ) {
            AuthenticationFeature()
        }
    )
}
#endif
