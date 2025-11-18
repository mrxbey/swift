//
// SettingsView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

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
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Link("Support", destination: URL(string: "https://example.com/support")!)

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
        }
    }

    private var formattedSyncDate: String {
        guard let date = store.lastSyncDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - SettingsFeature

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
        case exportDataTapped
        case syncNowTapped
        case signOutTapped
        case deleteAccountTapped
        case signOutConfirmation(PresentationAction<Alert>)
        case deleteAccountConfirmation(PresentationAction<Alert>)

        enum Alert: Sendable {
            case confirmSignOut
            case confirmDeleteAccount
        }
    }

    var body: some ReducerOf<Self> {
        BindableReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .exportDataTapped:
                // TODO: Implement export
                return .none

            case .syncNowTapped:
                state.lastSyncDate = Date()
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
                // TODO: Implement sign out
                return .none

            case .deleteAccountConfirmation(.presented(.confirmDeleteAccount)):
                // TODO: Implement account deletion
                return .none

            case .signOutConfirmation, .deleteAccountConfirmation:
                return .none
            }
        }
        .ifLet(\.$signOutConfirmation, action: \.signOutConfirmation)
        .ifLet(\.$deleteAccountConfirmation, action: \.deleteAccountConfirmation)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
#endif
