//
// HabitTrackerApp.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

@main
struct HabitTrackerApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

// MARK: - AppFeature

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var authState: AuthState = .loading
        var selectedTab: Tab = .today

        // Child features
        var authentication: AuthenticationFeature.State?
        var profileSetup: ProfileSetupFeature.State?
        var today = TodayFeature.State()
        var areas = AreasFeature.State()
        var insights = InsightsFeature.State()
        var programs = ProgramsFeature.State()
        var settings = SettingsFeature.State()
    }

    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case authenticated(userId: UUID, needsProfileSetup: Bool)
    }

    enum Action: Sendable {
        // Lifecycle
        case task
        case authStateChecked(TaskResult<(User?, Profile?)>)

        // Sync
        case startBackgroundSync(userId: UUID)
        case stopBackgroundSync
        case manualSync

        // Tab navigation
        case tabSelected(Tab)

        // Child features
        case authentication(AuthenticationFeature.Action)
        case profileSetup(ProfileSetupFeature.Action)
        case today(TodayFeature.Action)
        case areas(AreasFeature.Action)
        case insights(InsightsFeature.Action)
        case programs(ProgramsFeature.Action)
        case settings(SettingsFeature.Action)
    }

    enum Tab: Hashable, CaseIterable {
        case today, areas, insights, programs, settings

        var title: String {
            switch self {
            case .today: return "Today"
            case .areas: return "Areas"
            case .insights: return "Insights"
            case .programs: return "Inspire"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .today: return Theme.Icons.today
            case .areas: return Theme.Icons.areas
            case .insights: return Theme.Icons.insights
            case .programs: return Theme.Icons.programs
            case .settings: return Theme.Icons.settings
            }
        }
    }

    @Dependency(\.authService) var authService
    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.syncCoordinator) var syncCoordinator

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .task:
                return .run { send in
                    await send(.authStateChecked(
                        TaskResult {
                            let user = await authService.currentUser()
                            let profile: Profile? = if let user = user {
                                try? await fetchProfile(userId: user.id)
                            } else {
                                nil
                            }
                            return (user, profile)
                        }
                    ))
                }

            case let .authStateChecked(.success((user, profile))):
                if let user = user {
                    if profile == nil {
                        // User authenticated but needs profile setup
                        state.authState = .authenticated(userId: user.id, needsProfileSetup: true)
                        state.profileSetup = ProfileSetupFeature.State(userId: user.id)
                    } else {
                        // User authenticated and profile exists
                        state.authState = .authenticated(userId: user.id, needsProfileSetup: false)
                    }
                    // Start background sync for authenticated users
                    return .send(.startBackgroundSync(userId: user.id))
                } else {
                    // User not authenticated
                    state.authState = .unauthenticated
                    state.authentication = AuthenticationFeature.State()
                    // Stop background sync
                    return .send(.stopBackgroundSync)
                }

            case .authStateChecked(.failure):
                // Error checking auth state, assume unauthenticated
                state.authState = .unauthenticated
                state.authentication = AuthenticationFeature.State()
                return .send(.stopBackgroundSync)

            // MARK: Sync

            case let .startBackgroundSync(userId):
                return .run { _ in
                    await syncCoordinator.startBackgroundSync(userId: userId)
                    // Perform initial sync
                    await syncCoordinator.sync(userId: userId)
                }

            case .stopBackgroundSync:
                return .run { _ in
                    await syncCoordinator.stopBackgroundSync()
                }

            case .manualSync:
                // Manual sync can be triggered from settings or pull-to-refresh
                guard case let .authenticated(userId, _) = state.authState else {
                    return .none
                }
                return .run { _ in
                    await syncCoordinator.sync(userId: userId)
                }

            // MARK: Tab Navigation

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            // MARK: Authentication

            case .authentication(.delegate(.authenticationSucceeded(let session))):
                // Check if profile exists
                return .run { send in
                    await send(.authStateChecked(
                        TaskResult {
                            let profile = try? await fetchProfile(userId: session.user.id)
                            return (session.user, profile)
                        }
                    ))
                }

            case .authentication:
                return .none

            // MARK: Profile Setup

            case .profileSetup(.delegate(.profileSetupCompleted)):
                // Profile setup completed, mark as authenticated
                if case let .authenticated(userId, _) = state.authState {
                    state.authState = .authenticated(userId: userId, needsProfileSetup: false)
                    state.profileSetup = nil
                    // Start background sync now that profile is complete
                    return .send(.startBackgroundSync(userId: userId))
                }
                return .none

            case .profileSetup(.delegate(.profileSetupSkipped)):
                // Profile setup skipped, still mark as authenticated
                if case let .authenticated(userId, _) = state.authState {
                    state.authState = .authenticated(userId: userId, needsProfileSetup: false)
                    state.profileSetup = nil
                    // Start background sync even if profile setup was skipped
                    return .send(.startBackgroundSync(userId: userId))
                }
                return .none

            case .profileSetup:
                return .none

            // MARK: Child Features

            case .today, .areas, .insights, .programs, .settings:
                return .none
            }
        }
        .ifLet(\.authentication, action: \.authentication) {
            AuthenticationFeature()
        }
        .ifLet(\.profileSetup, action: \.profileSetup) {
            ProfileSetupFeature()
        }

        Scope(state: \.today, action: \.today) {
            TodayFeature()
        }
        Scope(state: \.areas, action: \.areas) {
            AreasFeature()
        }
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
        }
        Scope(state: \.programs, action: \.programs) {
            ProgramsFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
    }

    // MARK: - Helper Methods

    private func fetchProfile(userId: UUID) async throws -> Profile {
        let dto: ProfileDTO = try await supabaseClient
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return dto.toDomain
    }
}

// MARK: - AppView

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.authState {
            case .loading:
                loadingView

            case .unauthenticated:
                if let authenticationStore = store.scope(state: \.authentication, action: \.authentication) {
                    AuthenticationView(store: authenticationStore)
                }

            case .authenticated(_, let needsProfileSetup):
                if needsProfileSetup {
                    if let profileSetupStore = store.scope(state: \.profileSetup, action: \.profileSetup) {
                        ProfileSetupView(store: profileSetupStore)
                    }
                } else {
                    mainTabView
                }
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            Text("HabitTracker")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            ProgressView()
                .tint(.blue)
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            ForEach(AppFeature.Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(Theme.Colors.primary)
    }

    @ViewBuilder
    private func tabContent(for tab: AppFeature.Tab) -> some View {
        switch tab {
        case .today:
            TodayView(store: store.scope(state: \.today, action: \.today))

        case .areas:
            AreasView(store: store.scope(state: \.areas, action: \.areas))

        case .insights:
            InsightsView(store: store.scope(state: \.insights, action: \.insights))

        case .programs:
            ProgramsView(store: store.scope(state: \.programs, action: \.programs))

        case .settings:
            SettingsView(store: store.scope(state: \.settings, action: \.settings))
        }
    }
}

// MARK: - Placeholder Features

@Reducer
struct AreasFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct ProgramsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {}
    enum Action: Sendable {}
    var body: some ReducerOf<Self> {
        Reduce { state, action in .none }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
#endif
