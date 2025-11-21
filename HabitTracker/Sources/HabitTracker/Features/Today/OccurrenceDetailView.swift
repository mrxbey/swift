//
// OccurrenceDetailView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

public struct OccurrenceDetailView: View {
    @Bindable var store: StoreOf<OccurrenceDetailFeature>

    public init(store: StoreOf<OccurrenceDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with emoji and name
                    headerSection

                    // Status and progress
                    statusSection

                    // Goal details
                    if let goal = store.goal {
                        goalSection(goal: goal)
                    }

                    // Action buttons
                    actionsSection

                    // Error message
                    if let error = store.errorMessage {
                        errorSection(message: error)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Occurrence Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        store.send(.dismiss)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if !store.isEditingName {
                        Button {
                            store.send(.editNameTapped)
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .overlay {
                if store.isLoading {
                    ProgressView()
                }
            }
            .task {
                store.send(.task)
            }
            .sheet(isPresented: $store.isEditingName.sending(\.editNameTapped)) {
                nameEditorSheet
            }
        }
    }

    /// MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Emoji
            if let emoji = store.occurrence.displayEmoji {
                Text(emoji)
                    .font(.system(size: 64))
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
            }

            // Title
            Text(store.occurrence.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Date
            Text(store.occurrence.scheduledDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Override indicator
            if store.occurrence.nameOverride != nil || store.occurrence.emojiOverride != nil {
                Label("Custom name for this occurrence", systemImage: "pencil.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    /// MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 16) {
            // Status badge
            HStack(spacing: 8) {
                Image(systemName: store.occurrence.status.icon)
                    .foregroundColor(colorForStatus(store.occurrence.status))

                Text(store.occurrence.status.displayName)
                    .font(.headline)
                    .foregroundColor(colorForStatus(store.occurrence.status))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorForStatus(store.occurrence.status).opacity(0.1))
            )

            // Progress
            if store.occurrence.targetCount > 1 {
                VStack(spacing: 8) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("\(store.occurrence.completedCount)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("of \(store.occurrence.targetCount)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: store.occurrence.progress)
                        .tint(colorForStatus(store.occurrence.status))
                }
            }

            // Points
            if let snapshot = store.occurrence.contentSnapshot {
                HStack {
                    Label("\(snapshot.points) points", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    /// MARK: - Goal Section

    private func goalSection(goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Kind:")
                        .foregroundColor(.secondary)
                    Text(goal.kind.displayName)
                }

                HStack {
                    Text("Times per day:")
                        .foregroundColor(.secondary)
                    Text("\(goal.timesPerDay)")
                }

                HStack {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Text(goal.status.displayName)
                }

                if goal.keepUntilComplete {
                    Label("Keep until complete", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    /// MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Complete again button
            if store.canComplete {
                Button {
                    store.send(.completeAgainTapped)
                } label: {
                    Label("Complete Again", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
                .disabled(store.isPerformingAction)
            }

            // Undo completion button
            if store.canUndo {
                Button {
                    store.send(.undoCompletionTapped)
                } label: {
                    Label("Undo Completion", systemImage: "arrow.uturn.backward.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
                .disabled(store.isPerformingAction)
            }

            // Skip button
            if store.canSkip {
                Button {
                    store.send(.skipTapped)
                } label: {
                    Label("Skip", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                }
                .disabled(store.isPerformingAction)
            }

            if store.isPerformingAction {
                ProgressView()
                    .padding()
            }
        }
    }

    /// MARK: - Error Section

    private func errorSection(message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(12)
    }

    /// MARK: - Name Editor Sheet

    private var nameEditorSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $store.customName.sending(\.nameChanged))

                    if let emoji = store.customEmoji {
                        HStack {
                            Text("Emoji: \(emoji)")

                            Spacer()

                            Button("Change") {
                                // Simple emoji cycle for now
                                let emojis = ["🎯", "💪", "📚", "🧘", "💧", "⭐", "✨", "🔥"]
                                if let current = store.customEmoji,
                                   let index = emojis.firstIndex(of: current) {
                                    let nextIndex = (index + 1) % emojis.count
                                    store.send(.emojiChanged(emojis[nextIndex]))
                                } else {
                                    store.send(.emojiChanged(emojis.first))
                                }
                            }
                        }
                    } else {
                        Button("Add Emoji") {
                            store.send(.emojiChanged("🎯"))
                        }
                    }
                } header: {
                    Text("Customize Occurrence")
                } footer: {
                    Text("This custom name will only apply to this specific occurrence, not the goal itself.")
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelNameEdit)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.saveNameTapped)
                    }
                    .fontWeight(.semibold)
                    .disabled(store.customName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .disabled(store.isPerformingAction)
            .overlay {
                if store.isPerformingAction {
                    ProgressView()
                }
            }
        }
    }

    /// MARK: - Helper Methods

    private func colorForStatus(_ status: OccurrenceStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .completed: return .green
        case .skipped: return .blue
        case .missed: return .red
        case .cancelled: return .orange
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Pending Occurrence") {
    OccurrenceDetailView(
        store: Store(
            initialState: OccurrenceDetailFeature.State(occurrence: .mockPending)
        ) {
            OccurrenceDetailFeature()
        }
    )
}

#Preview("Completed Occurrence") {
    OccurrenceDetailView(
        store: Store(
            initialState: OccurrenceDetailFeature.State(occurrence: .mockCompleted)
        ) {
            OccurrenceDetailFeature()
        }
    )
}

#Preview("Partial Progress") {
    OccurrenceDetailView(
        store: Store(
            initialState: OccurrenceDetailFeature.State(occurrence: .mockPartial)
        ) {
            OccurrenceDetailFeature()
        }
    )
}
#endif
