//
// SettingsView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture
import Dependencies

/// External links configuration
/// Note: Update these URLs with actual production URLs before release
private enum ExternalLinks {
    static let privacyPolicy = URL(string: "https://example.com/privacy")
    static let termsOfService = URL(string: "https://example.com/terms")
    static let support = URL(string: "https://example.com/support")
}

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        NavigationStack {
            Form {
                // Profile section
                Section("Profile") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(Theme.Colors.primary)

                        VStack(alignment: .leading) {
                            Text(store.displayName)
                                .font(Theme.Typography.bodyBold)

                            Text(store.email)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xSmall)
                }

                // Preferences section
                Section("Preferences") {
                    Picker("Timezone", selection: $store.timezone) {
                        ForEach(store.availableTimezones, id: \.self) { tz in
                            Text(tz).tag(tz)
                        }
                    }

                    Toggle("Daily Reminder", isOn: $store.dailyReminderEnabled)

                    if store.dailyReminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $store.dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // Notifications section
                Section("Notifications") {
                    Toggle("Goal Reminders", isOn: $store.goalRemindersEnabled)

                    Toggle("Streak Notifications", isOn: $store.streakNotificationsEnabled)

                    Toggle("Weekly Summary", isOn: $store.weeklySummaryEnabled)
                }

                // Appearance section
                Section("Appearance") {
                    Picker("Theme", selection: $store.selectedTheme) {
                        Text("System").tag(Theme.system)
                        Text("Light").tag(Theme.light)
                        Text("Dark").tag(Theme.dark)
                    }

                    Toggle("Show Emoji", isOn: $store.showEmoji)
                }

                // Data section
                Section("Data") {
                    Button("Export Data") {
                        store.send(.exportDataTapped)
                    }

                    Button("Sync Now") {
                        store.send(.syncNowTapped)
                    }

                    if store.lastSyncDate != nil {
                        HStack {
                            Text("Last Synced")
                            Spacer()
                            Text(formattedSyncDate)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .font(Theme.Typography.caption)
                    }
                }

                // About section
                Section("About") {
                    if let url = ExternalLinks.privacyPolicy {
                        Link("Privacy Policy", destination: url)
                    }
                    if let url = ExternalLinks.termsOfService {
                        Link("Terms of Service", destination: url)
                    }
                    if let url = ExternalLinks.support {
                        Link("Support", destination: url)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(store.appVersion)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                // Account section
                Section {
                    Button("Sign Out", role: .destructive) {
                        store.send(.signOutTapped)
                    }

                    Button("Delete Account", role: .destructive) {
                        store.send(.deleteAccountTapped)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert($store.scope(state: \.signOutConfirmation, action: \.signOutConfirmation))
            .alert($store.scope(state: \.deleteAccountConfirmation, action: \.deleteAccountConfirmation))
            .task {
                store.send(.task)
            }
        }
    }

    private var formattedSyncDate: String {
        guard let date = store.lastSyncDate else { return "Never" }
        return Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    // Cached formatter to avoid creating new instance on every access
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

/// MARK: - SettingsFeature

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        // Profile
        var displayName: String = "User"
        var email: String = "user@example.com"

        // Preferences
        var timezone: String = TimeZone.current.identifier
        var availableTimezones: [String] = TimeZone.knownTimeZoneIdentifiers.sorted()
        var dailyReminderEnabled: Bool = false
        var dailyReminderTime: Date = Date()

        // Notifications
        var goalRemindersEnabled: Bool = true
        var streakNotificationsEnabled: Bool = true
        var weeklySummaryEnabled: Bool = true

        // Appearance
        var selectedTheme: Theme = .system
        var showEmoji: Bool = true

        // Data
        var lastSyncDate: Date? = Date()

        // About
        var appVersion: String = "1.0.0"

        // Alerts
        @Presents var signOutConfirmation: AlertState<Action.Alert>?
        @Presents var deleteAccountConfirmation: AlertState<Action.Alert>?

        enum Theme: Hashable {
            case system, light, dark
        }
    }

    enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)
        case task
        case profileLoaded(displayName: String, email: String)
        case exportDataTapped
        case exportResponse(TaskResult<URL>)
        case syncNowTapped
        case syncResponse(TaskResult<Date>)
        case signOutTapped
        case deleteAccountTapped
        case signOutConfirmation(PresentationAction<Alert>)
        case deleteAccountConfirmation(PresentationAction<Alert>)
        case signOutResponse(TaskResult<Void>)
        case deleteAccountResponse(TaskResult<Void>)

        enum Alert: Sendable {
            case confirmSignOut
            case confirmDeleteAccount
        }
    }

    @Dependency(\.authService) var authService
    @Dependency(\.syncCoordinator) var syncCoordinator
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindableReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .task:
                // Load user profile on view appear
                return .run { send in
                    if let user = await authService.currentUser() {
                        await send(.profileLoaded(
                            displayName: user.email ?? "User",
                            email: user.email ?? ""
                        ))
                    }
                }

            case .profileLoaded(let displayName, let email):
                state.displayName = displayName
                state.email = email
                return .none

            case .exportDataTapped:
                // Export user data to JSON file
                return .run { send in
                    await send(.exportResponse(
                        TaskResult {
                            // TODO: Implement full data export
                            // For now, create a placeholder export
                            let exportData: [String: Any] = [
                                "exported_at": ISO8601DateFormatter().string(from: Date()),
                                "user_email": await authService.currentUser()?.email ?? "",
                                "version": "1.0.0"
                            ]

                            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("habit_tracker_export_\(Date().timeIntervalSince1970).json")
                            try jsonData.write(to: fileURL)
                            return fileURL
                        }
                    ))
                }

            case .exportResponse(.success(let fileURL)):
                // TODO: Present share sheet with the exported file
                return .none

            case .exportResponse(.failure):
                // TODO: Show error alert
                return .none

            case .syncNowTapped:
                // Trigger manual sync
                return .run { send in
                    await send(.syncResponse(
                        TaskResult {
                            try await syncCoordinator.sync()
                            return Date()
                        }
                    ))
                }

            case .syncResponse(.success(let syncDate)):
                state.lastSyncDate = syncDate
                return .none

            case .syncResponse(.failure):
                // TODO: Show error alert
                return .none

            case .signOutTapped:
                state.signOutConfirmation = AlertState {
                    TextState("Sign Out")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmSignOut) {
                        TextState("Sign Out")
                    }
                } message: {
                    TextState("Are you sure you want to sign out?")
                }
                return .none

            case .deleteAccountTapped:
                state.deleteAccountConfirmation = AlertState {
                    TextState("Delete Account")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeleteAccount) {
                        TextState("Delete")
                    }
                } message: {
                    TextState("This will permanently delete your account and all data. This cannot be undone.")
                }
                return .none

            case .signOutConfirmation(.presented(.confirmSignOut)):
                // Perform sign out
                return .run { send in
                    await send(.signOutResponse(
                        TaskResult {
                            try await authService.signOut()
                        }
                    ))
                }

            case .signOutResponse(.success):
                // Sign out successful - dismiss will be handled by parent
                return .none

            case .signOutResponse(.failure):
                // TODO: Show error alert
                return .none

            case .deleteAccountConfirmation(.presented(.confirmDeleteAccount)):
                // Perform account deletion
                return .run { send in
                    await send(.deleteAccountResponse(
                        TaskResult {
                            // TODO: Implement account deletion API call
                            // For now, just sign out
                            try await authService.signOut()
                        }
                    ))
                }

            case .deleteAccountResponse(.success):
                // Account deleted - dismiss will be handled by parent
                return .none

            case .deleteAccountResponse(.failure):
                // TODO: Show error alert
                return .none

            case .signOutConfirmation, .deleteAccountConfirmation:
                return .none
            }
        }
        .ifLet(\.$signOutConfirmation, action: \.signOutConfirmation)
        .ifLet(\.$deleteAccountConfirmation, action: \.deleteAccountConfirmation)
    }
}

/// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
#endif
