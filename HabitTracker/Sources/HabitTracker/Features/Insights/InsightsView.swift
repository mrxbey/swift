//
// InsightsView.swift
// HabitTracker
//

import SwiftUI
import ComposableArchitecture
import Charts

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.large) {
                    // Streaks section
                    streaksSection

                    // Points section
                    pointsSection

                    // Top goals section
                    topGoalsSection

                    // Completion rate chart
                    completionRateSection
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Insights")
            .task {
                store.send(.task)
            }
        }
    }

    /// MARK: - Streaks Section

    private var streaksSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("Streaks")
                .font(Theme.Typography.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Theme.Spacing.medium) {
                StreakCard(
                    title: "Current Streak",
                    value: store.currentStreak,
                    icon: Theme.Icons.streak,
                    color: .orange
                )

                StreakCard(
                    title: "Longest Streak",
                    value: store.longestStreak,
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }

    /// MARK: - Points Section

    private var pointsSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("Points")
                .font(Theme.Typography.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Theme.Spacing.medium) {
                PointsCard(
                    title: "Today",
                    points: store.pointsToday,
                    color: .blue
                )

                PointsCard(
                    title: "This Week",
                    points: store.pointsThisWeek,
                    color: .purple
                )

                PointsCard(
                    title: "All Time",
                    points: store.pointsAllTime,
                    color: .green
                )
            }
        }
    }

    /// MARK: - Top Goals Section

    private var topGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Most Completed (Last 30 Days)")
                .font(Theme.Typography.title3)

            if store.topGoals.isEmpty {
                Text("No data yet")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
            } else {
                ForEach(store.topGoals) { item in
                    TopGoalRow(item: item)
                }
            }
        }
    }

    /// MARK: - Completion Rate Section

    private var completionRateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Completion Rate (Last 7 Days)")
                .font(Theme.Typography.title3)

            if store.completionData.isEmpty {
                Text("No data yet")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
            } else {
                CompletionChart(data: store.completionData)
                    .frame(height: 200)
                    .padding()
                    .cardStyle()
            }
        }
    }
}

/// MARK: - Supporting Views

struct StreakCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text("\(value)")
                .font(Theme.Typography.number)
                .foregroundColor(Theme.Colors.text)

            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)

            Text(value == 1 ? "day" : "days")
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct PointsCard: View {
    let title: String
    let points: Int
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            Text("\(points)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct TopGoalRow: View {
    let item: TopGoalItem

    var body: some View {
        HStack {
            Text(item.rank)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 30)

            if let emoji = item.emoji {
                Text(emoji)
                    .font(.title3)
            }

            Text(item.title)
                .font(Theme.Typography.body)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.completionCount)")
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(Theme.Colors.success)

                Text("completions")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding()
        .cardStyle()
    }

    private var rankColor: Color {
        switch item.rank {
        case "🥇": return .yellow
        case "🥈": return .gray
        case "🥉": return .orange
        default: return Theme.Colors.secondaryText
        }
    }
}

struct CompletionChart: View {
    let data: [CompletionDataPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Rate", point.completionRate)
            )
            .foregroundStyle(
                point.completionRate >= 0.8 ? .green :
                point.completionRate >= 0.5 ? .orange : .red
            )
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let percent = value.as(Double.self) {
                        Text("\(Int(percent * 100))%")
                            .font(Theme.Typography.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(Theme.Typography.caption)
            }
        }
    }
}

/// MARK: - InsightsFeature

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var pointsToday: Int = 0
        var pointsThisWeek: Int = 0
        var pointsAllTime: Int = 0
        var topGoals: IdentifiedArrayOf<TopGoalItem> = []
        var completionData: [CompletionDataPoint] = []
        var isLoading = false
    }

    enum Action: Sendable {
        case task
        case streaksResponse(TaskResult<(current: Int, longest: Int)>)
        case pointsResponse(TaskResult<(today: Int, week: Int, allTime: Int)>)
        case topGoalsResponse(TaskResult<[TopGoalItem]>)
        case completionDataResponse(TaskResult<[CompletionDataPoint]>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .none

            case .streaksResponse(.success(let streaks)):
                state.currentStreak = streaks.current
                state.longestStreak = streaks.longest
                return .none

            case .streaksResponse(.failure):
                return .none

            case .pointsResponse(.success(let points)):
                state.pointsToday = points.today
                state.pointsThisWeek = points.week
                state.pointsAllTime = points.allTime
                state.isLoading = false
                return .none

            case .pointsResponse(.failure):
                state.isLoading = false
                return .none

            case .topGoalsResponse(.success(let goals)):
                state.topGoals = IdentifiedArray(uniqueElements: goals)
                return .none

            case .topGoalsResponse(.failure):
                return .none

            case .completionDataResponse(.success(let data)):
                state.completionData = data
                return .none

            case .completionDataResponse(.failure):
                return .none
            }
        }
    }
}

/// MARK: - Models

struct TopGoalItem: Identifiable, Equatable {
    let id: UUID
    let rank: String
    let title: String
    let emoji: String?
    let completionCount: Int

    init(id: UUID, rankNumber: Int, title: String, emoji: String?, completionCount: Int) {
        self.id = id
        self.rank = switch rankNumber {
        case 1: "🥇"
        case 2: "🥈"
        case 3: "🥉"
        default: "\(rankNumber)"
        }
        self.title = title
        self.emoji = emoji
        self.completionCount = completionCount
    }
}

struct CompletionDataPoint: Identifiable, Equatable {
    let id: UUID = UUID()
    let date: Date
    let completionRate: Double
}

/// MARK: - Preview

#if DEBUG
#Preview {
    InsightsView(
        store: Store(initialState: InsightsFeature.State(
            currentStreak: 7,
            longestStreak: 21,
            pointsToday: 45,
            pointsThisWeek: 215,
            pointsAllTime: 1234,
            topGoals: [
                TopGoalItem(id: UUID(), rankNumber: 1, title: "Morning Meditation", emoji: "🧘", completionCount: 28),
                TopGoalItem(id: UUID(), rankNumber: 2, title: "Workout", emoji: "💪", completionCount: 24),
                TopGoalItem(id: UUID(), rankNumber: 3, title: "Read", emoji: "📚", completionCount: 20)
            ],
            completionData: (0..<7).map { days in
                CompletionDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -days, to: Date())!,
                    completionRate: Double.random(in: 0.5...1.0)
                )
            }.reversed()
        )) {
            InsightsFeature()
        }
    )
}
#endif
