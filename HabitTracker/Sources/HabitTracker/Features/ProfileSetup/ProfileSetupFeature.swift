import ComposableArchitecture
import Foundation

/// Feature for setting up user profile after first sign in
///
/// Collects display name, timezone, and preferences.
@Reducer
public struct ProfileSetupFeature {

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var userId: UUID
        public var displayName: String = ""
        public var selectedTimezone: String = TimeZone.current.identifier
        public var weekStartsOn: Int = 1 // 1 = Monday
        public var dailyReminderEnabled: Bool = false
        public var dailyReminderTime: Date = {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        public var isLoading: Bool = false
        public var error: String?

        // Validation
        public var isValid: Bool {
            !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        }

        public init(userId: UUID) {
            self.userId = userId
        }
    }

    // MARK: - Action

    public enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case skipTapped
        case saveResponse(TaskResult<Profile>)
        case delegate(Delegate)

        public enum Delegate: Sendable {
            case profileSetupCompleted(Profile)
            case profileSetupSkipped
        }
    }

    // MARK: - Dependencies

    @Dependency(\.supabaseClient) var supabaseClient

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        BindableReducer()

        Reduce { state, action in
            switch action {

            case .binding:
                return .none

            case .saveTapped:
                guard state.isValid else {
                    state.error = "Please enter your name"
                    return .none
                }

                state.isLoading = true
                state.error = nil

                let profile = Profile(
                    id: state.userId,
                    displayName: state.displayName.trimmingCharacters(in: .whitespaces),
                    avatarURL: nil,
                    timezone: state.selectedTimezone,
                    weekStartsOn: state.weekStartsOn,
                    dailyReminderEnabled: state.dailyReminderEnabled,
                    dailyReminderTime: state.dailyReminderEnabled ? state.dailyReminderTime : nil,
                    totalPoints: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                return .run { send in
                    await send(.saveResponse(
                        TaskResult {
                            try await saveProfile(profile)
                            return profile
                        }
                    ))
                }

            case .skipTapped:
                // Create minimal profile
                let profile = Profile(
                    id: state.userId,
                    displayName: nil,
                    avatarURL: nil,
                    timezone: TimeZone.current.identifier,
                    weekStartsOn: 1,
                    dailyReminderEnabled: false,
                    dailyReminderTime: nil,
                    totalPoints: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                return .run { send in
                    await send(.saveResponse(
                        TaskResult {
                            try await saveProfile(profile)
                            return profile
                        }
                    ))
                }

            case let .saveResponse(.success(profile)):
                state.isLoading = false
                return .send(.delegate(.profileSetupCompleted(profile)))

            case let .saveResponse(.failure(error)):
                state.isLoading = false
                state.error = "Failed to save profile: \(error.localizedDescription)"
                return .none

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Helper Methods

    private func saveProfile(_ profile: Profile) async throws {
        let dto = ProfileDTO(from: profile)

        try await supabaseClient
            .from("profiles")
            .upsert(dto)
            .execute()
    }
}

// MARK: - Dependency Key

extension DependencyValues {
    public var supabaseClient: SupabaseClient {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}

private enum SupabaseClientKey: DependencyKey {
    static let liveValue: SupabaseClient = SupabaseService.shared.getClient()
    static let testValue: SupabaseClient = SupabaseService.shared.getClient()
    static let previewValue: SupabaseClient = SupabaseService.shared.getClient()
}
