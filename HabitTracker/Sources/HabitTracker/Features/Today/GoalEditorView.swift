//
// GoalEditorView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

public struct GoalEditorView: View {
    @Bindable var store: StoreOf<GoalEditorFeature>

    public init(store: StoreOf<GoalEditorFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Title and Emoji
                Section {
                    HStack {
                        TextField("Goal title", text: $store.title.sending(\.titleChanged))
                            .textInputAutocapitalization(.sentences)

                        if let emoji = store.emoji {
                            Text(emoji)
                                .font(.title2)
                        }

                        Button {
                            // TODO: Show emoji picker
                            // For now, toggle a few common emojis
                            if store.emoji == nil {
                                store.send(.emojiChanged("🎯"))
                            } else if store.emoji == "🎯" {
                                store.send(.emojiChanged("💪"))
                            } else if store.emoji == "💪" {
                                store.send(.emojiChanged("📚"))
                            } else {
                                store.send(.emojiChanged(nil))
                            }
                        } label: {
                            Image(systemName: store.emoji == nil ? "face.smiling" : "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !store.title.isEmpty && store.title.count > 90 {
                        Text("\(store.title.count)/100")
                            .font(.caption)
                            .foregroundColor(store.title.count > 100 ? .red : .secondary)
                    }
                } header: {
                    Text("Details")
                } footer: {
                    if let error = store.errorMessage, error.contains("title") || error.contains("Title") {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                // Area Selection
                Section {
                    if store.isLoadingAreas {
                        HStack {
                            Text("Loading areas...")
                            Spacer()
                            ProgressView()
                        }
                    } else if store.availableAreas.isEmpty {
                        Text("No areas available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Area", selection: Binding(
                            get: { store.areaId ?? store.availableAreas.first?.id ?? UUID() },
                            set: { store.send(.areaSelected($0)) }
                        )) {
                            ForEach(store.availableAreas, id: \.id) { area in
                                HStack {
                                    if let emoji = area.emoji {
                                        Text(emoji)
                                    }
                                    Text(area.name)
                                }
                                .tag(area.id)
                            }
                        }
                    }
                } header: {
                    Text("Area")
                } footer: {
                    if let error = store.errorMessage, error.contains("area") || error.contains("Area") {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                // Goal Type
                Section {
                    Picker("Type", selection: $store.kind.sending(\.kindSelected)) {
                        ForEach(GoalKind.allCases, id: \.self) { kind in
                            Label(kind.displayName, systemImage: kind.icon)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Goal Type")
                }

                // Frequency & Points
                Section {
                    Stepper("Times per day: \(store.timesPerDay)", value: Binding(
                        get: { store.timesPerDay },
                        set: { store.send(.timesPerDayChanged($0)) }
                    ), in: 1...100)

                    Stepper("Points per completion: \(store.pointsPerCompletion)", value: Binding(
                        get: { store.pointsPerCompletion },
                        set: { store.send(.pointsChanged($0)) }
                    ), in: 1...100)
                } header: {
                    Text("Settings")
                } footer: {
                    if let error = store.errorMessage,
                       (error.contains("points") || error.contains("Points") ||
                        error.contains("times") || error.contains("Times")) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                // Linked Exercise (optional)
                Section {
                    Picker("Linked exercise", selection: $store.linkedExerciseKey.sending(\.linkedExerciseKeySelected)) {
                        Text("None")
                            .tag(nil as LinkedExercise?)

                        ForEach(LinkedExercise.allCases, id: \.self) { exercise in
                            HStack {
                                Text(exercise.defaultEmoji)
                                Text(exercise.displayName)
                            }
                            .tag(exercise as LinkedExercise?)
                        }
                    }
                } header: {
                    Text("Linked Exercise (Optional)")
                } footer: {
                    Text("Link this goal to a specific exercise or tracking activity")
                        .font(.caption)
                }

                // Advanced Options
                Section {
                    Toggle("Keep until complete", isOn: Binding(
                        get: { store.keepUntilComplete },
                        set: { _ in store.send(.keepUntilCompleteToggled) }
                    ))
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("When enabled, this goal will remain active until explicitly completed, even for task-type goals")
                        .font(.caption)
                }

                // Error message (general)
                if let error = store.errorMessage,
                   !error.contains("title") && !error.contains("Title") &&
                   !error.contains("area") && !error.contains("Area") &&
                   !error.contains("points") && !error.contains("Points") &&
                   !error.contains("times") && !error.contains("Times") {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(store.mode.isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelTapped)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.saveTapped)
                    }
                    .disabled(!store.canSave)
                    .fontWeight(.semibold)
                }
            }
            .disabled(store.isSaving)
            .overlay {
                if store.isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Saving...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            .task {
                store.send(.task)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Create Goal") {
    GoalEditorView(
        store: Store(
            initialState: GoalEditorFeature.State(mode: .create)
        ) {
            GoalEditorFeature()
        }
    )
}

#Preview("Edit Goal") {
    GoalEditorView(
        store: Store(
            initialState: GoalEditorFeature.State(
                mode: .edit(Goal.mockMeditation)
            )
        ) {
            GoalEditorFeature()
        }
    )
}
#endif
