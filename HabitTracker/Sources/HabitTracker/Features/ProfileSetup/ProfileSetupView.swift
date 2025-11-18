import SwiftUI
import ComposableArchitecture

/// View for setting up user profile
///
/// Shown after first sign in to collect user preferences.
public struct ProfileSetupView: View {
    @Bindable var store: StoreOf<ProfileSetupFeature>

    public init(store: StoreOf<ProfileSetupFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Profile fields
                    profileFieldsSection

                    // Error message
                    if let error = store.error {
                        errorBanner(error)
                    }

                    // Buttons
                    buttonsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        store.send(.skipTapped)
                    }
                    .disabled(store.isLoading)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
                Text("Welcome to HabitTracker!")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Let's set up your profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Profile Fields

    private var profileFieldsSection: some View {
        VStack(spacing: 24) {
            // Display name
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.headline)

                TextField("Your name", text: $store.displayName)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .disabled(store.isLoading)
            }

            // Timezone
            VStack(alignment: .leading, spacing: 8) {
                Text("Timezone")
                    .font(.headline)

                Picker("Timezone", selection: $store.selectedTimezone) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { timezone in
                        Text(timezone.replacingOccurrences(of: "_", with: " "))
                            .tag(timezone)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .disabled(store.isLoading)
            }

            // Week starts on
            VStack(alignment: .leading, spacing: 8) {
                Text("Week Starts On")
                    .font(.headline)

                Picker("Week Starts On", selection: $store.weekStartsOn) {
                    Text("Monday").tag(1)
                    Text("Tuesday").tag(2)
                    Text("Wednesday").tag(3)
                    Text("Thursday").tag(4)
                    Text("Friday").tag(5)
                    Text("Saturday").tag(6)
                    Text("Sunday").tag(7)
                }
                .pickerStyle(.segmented)
                .disabled(store.isLoading)
            }

            // Daily reminder
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $store.dailyReminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminder")
                            .font(.headline)
                        Text("Get a daily notification to check in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(store.isLoading)

                if store.dailyReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: $store.dailyReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .disabled(store.isLoading)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: 16) {
            Button {
                store.send(.saveTapped)
            } label: {
                ZStack {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(store.isValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!store.isValid || store.isLoading)

            Text("You can always change these settings later")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

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
}

// MARK: - Preview

#if DEBUG
#Preview {
    ProfileSetupView(
        store: Store(
            initialState: ProfileSetupFeature.State(userId: UUID())
        ) {
            ProfileSetupFeature()
        }
    )
}
#endif
