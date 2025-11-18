//
// TodayView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture

public struct TodayView: View {
    @Bindable var store: StoreOf<TodayFeature>

    public init(store: StoreOf<TodayFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Header with date and stats
                    headerSection

                    // Recommendations
                    if !store.recommendations.isEmpty {
                        recommendationsSection
                    }

                    // Water goal (if exists)
                    if store.waterProgress != nil {
                        waterSection
                    }

                    // Today's occurrences
                    occurrencesSection
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addGoalTapped)
                    } label: {
                        Image(systemName: Theme.Icons.add)
                            .imageScale(.large)
                    }
                }
            }
            .refreshable {
                store.send(.refresh)
            }
            .overlay {
                if store.isLoading && store.occurrences.isEmpty {
                    ProgressView()
                }
            }
            .sheet(
                item: $store.scope(state: \.goalEditor, action: \.goalEditor)
            ) { store in
                GoalEditorView(store: store)
            }
            .sheet(
                item: $store.scope(state: \.occurrenceDetail, action: \.occurrenceDetail)
            ) { store in
                OccurrenceDetailView(store: store)
            }
            .task {
                store.send(.task)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.small) {
            // Date
            Text(formattedDate)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)

            // Progress ring with stats
            HStack(spacing: Theme.Spacing.xLarge) {
                // Progress ring
                ZStack {
                    ProgressRing(
                        progress: store.completionRate,
                        lineWidth: 12,
                        size: 120
                    )

                    VStack(spacing: 4) {
                        Text("\(store.completedCount)")
                            .font(Theme.Typography.number)
                            .foregroundColor(Theme.Colors.text)

                        Text("of \(store.totalTargets)")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    StatRow(
                        icon: Theme.Icons.complete,
                        label: "Completed",
                        value: "\(store.completedCount)",
                        color: Theme.Colors.success
                    )

                    StatRow(
                        icon: Theme.Icons.pending,
                        label: "Remaining",
                        value: "\(store.totalTargets - store.completedCount)",
                        color: Theme.Colors.secondaryText
                    )

                    StatRow(
                        icon: Theme.Icons.points,
                        label: "Points Today",
                        value: "\(pointsEarned)",
                        color: Theme.Colors.accent
                    )
                }
            }
            .padding()
            .cardStyle()
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Goals of the Day")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.medium) {
                    ForEach(store.recommendations) { goal in
                        RecommendationCard(goal: goal) {
                            store.send(.recommendationTapped(goal))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Water Section

    private var waterSection: some View {
        Group {
            if let progress = store.waterProgress {
                WaterCard(progress: progress) { amount in
                    store.send(.addWaterMeasurement(amount))
                }
            }
        }
    }

    // MARK: - Occurrences Section

    private var occurrencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Your Goals")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.text)

            if store.occurrences.isEmpty {
                emptyState
            } else {
                // Pending occurrences
                if !store.pendingOccurrences.isEmpty {
                    ForEach(store.pendingOccurrences) { occurrence in
                        OccurrenceRow(
                            occurrence: occurrence,
                            onTap: { store.send(.occurrenceTapped(occurrence.id)) },
                            onComplete: { store.send(.completeTick(occurrence.id)) },
                            onSkip: { store.send(.skipOccurrence(occurrence.id)) }
                        )
                    }
                }

                // Completed occurrences (collapsible)
                if !store.completedOccurrences.isEmpty {
                    DisclosureGroup("Completed (\(store.completedOccurrences.count))") {
                        ForEach(store.completedOccurrences) { occurrence in
                            OccurrenceRow(
                                occurrence: occurrence,
                                onTap: { store.send(.occurrenceTapped(occurrence.id)) },
                                onComplete: { store.send(.completeTick(occurrence.id)) },
                                onSkip: { store.send(.skipOccurrence(occurrence.id)) }
                            )
                        }
                    }
                    .font(Theme.Typography.bodyBold)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText)

            Text("No goals for today")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)

            Text("Tap the + button to add your first goal")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxxLarge)
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: store.selectedDate)
    }

    private var pointsEarned: Int {
        store.occurrences
            .filter { $0.isComplete }
            .reduce(0) { $0 + ($1.pointsEarned) }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)

            Spacer()

            Text(value)
                .font(Theme.Typography.bodyBold)
                .foregroundColor(color)
        }
    }
}

struct RecommendationCard: View {
    let goal: Goal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                if let emoji = goal.emoji {
                    Text(emoji)
                        .font(Theme.Typography.emoji)
                }

                Text(goal.title)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)

                Text("Tap to add")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primary)
            }
            .frame(width: 140)
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct WaterCard: View {
    let progress: WaterProgress
    let onAddWater: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image(systemName: Theme.Icons.water)
                    .foregroundColor(.blue)

                Text("Water Intake")
                    .font(Theme.Typography.bodyBold)

                Spacer()

                Text("\(Int(progress.consumed))/\(Int(progress.target)) \(progress.unit.displayName)")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.separator.opacity(0.3))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress.progress)
                        .animation(Theme.Animation.spring, value: progress.progress)
                }
            }
            .frame(height: 12)

            // Quick add buttons
            HStack(spacing: Theme.Spacing.small) {
                ForEach([100, 250, 500], id: \.self) { amount in
                    Button("+\(amount)ml") {
                        onAddWater(Double(amount))
                    }
                    .font(Theme.Typography.footnote)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.xSmall)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .foregroundColor(Theme.Colors.primary)
                    .cornerRadius(Theme.CornerRadius.small)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct OccurrenceRow: View {
    let occurrence: GoalOccurrence
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.medium) {
                // Emoji or status icon
                if let emoji = occurrence.displayEmoji {
                    Text(emoji)
                        .font(.title2)
                } else {
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundColor(statusColor)
                }

                // Title and progress
                VStack(alignment: .leading, spacing: 4) {
                    Text(occurrence.displayTitle)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)

                    if occurrence.targetCount > 1 {
                        HStack(spacing: 4) {
                            ForEach(0..<occurrence.targetCount, id: \.self) { index in
                                Circle()
                                    .fill(index < occurrence.completedCount ? Theme.Colors.success : Theme.Colors.separator)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }

                Spacer()

                // Actions
                if occurrence.canComplete {
                    Button(action: onComplete) {
                        Image(systemName: Theme.Icons.complete)
                            .font(.title2)
                            .foregroundColor(Theme.Colors.success)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if occurrence.isPending {
                Button("Skip", systemImage: "arrow.right") {
                    onSkip()
                }
                .tint(.blue)
            }
        }
    }

    private var statusIcon: String {
        occurrence.status.icon
    }

    private var statusColor: Color {
        Theme.Colors.statusColor(occurrence.status)
    }
}

// MARK: - Placeholder Views

struct GoalEditorView: View {
    let store: StoreOf<GoalEditorFeature>

    var body: some View {
        Text("Goal Editor")
            .navigationTitle("New Goal")
    }
}

struct OccurrenceDetailView: View {
    let store: StoreOf<OccurrenceDetailFeature>

    var body: some View {
        Text("Occurrence Detail")
            .navigationTitle("Details")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Today View") {
    TodayView(
        store: Store(initialState: TodayFeature.State()) {
            TodayFeature()
        } withDependencies: {
            $0.occurrenceRepository = MockOccurrenceRepository()
        }
    )
}

actor MockOccurrenceRepository: OccurrenceRepository {
    func fetchToday() async throws -> [GoalOccurrence] {
        [.mockPending, .mockPartial, .mockCompleted]
    }

    func fetchForDate(_ date: Date) async throws -> [GoalOccurrence] {
        [.mockPending, .mockPartial, .mockCompleted]
    }

    func completeTick(_ id: UUID) async throws {
        // Mock implementation
    }

    func skip(_ id: UUID, reason: String?) async throws {
        // Mock implementation
    }
}

protocol OccurrenceRepository: Sendable {
    func fetchToday() async throws -> [GoalOccurrence]
    func fetchForDate(_ date: Date) async throws -> [GoalOccurrence]
    func completeTick(_ id: UUID) async throws
    func skip(_ id: UUID, reason: String?) async throws
}

protocol GoalRepository: Sendable {
    func fetchRecommendations(for date: Date) async throws -> [Goal]
}

protocol MeasurementRepository: Sendable {
    func fetchWaterProgress(for date: Date) async throws -> WaterProgress?
    func addMeasurement(goalId: UUID, value: Double, unit: UnitKind) async throws
}
#endif
