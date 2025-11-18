import ComposableArchitecture
import Foundation

/// Feature for the Today screen - shows today's occurrences and recommendations
@Reducer
public struct TodayFeature {

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var occurrences: IdentifiedArrayOf<GoalOccurrence> = []
        public var recommendations: [Goal] = []
        public var waterGoal: Goal?
        public var waterProgress: WaterProgress?
        public var selectedDate: Date = Date()
        public var isLoading: Bool = false
        public var error: String?

        // Child features
        @Presents public var goalEditor: GoalEditorFeature.State?
        @Presents public var occurrenceDetail: OccurrenceDetailFeature.State?

        // Computed properties
        public var totalTargets: Int {
            occurrences.count
        }

        public var completedCount: Int {
            occurrences.filter { $0.isComplete }.count
        }

        public var completionRate: Double {
            guard totalTargets > 0 else { return 0 }
            return Double(completedCount) / Double(totalTargets)
        }

        public var pendingOccurrences: IdentifiedArrayOf<GoalOccurrence> {
            IdentifiedArray(uniqueElements: occurrences.filter { $0.isPending })
        }

        public var completedOccurrences: IdentifiedArrayOf<GoalOccurrence> {
            IdentifiedArray(uniqueElements: occurrences.filter { $0.isComplete })
        }

        public init() {}
    }

    // MARK: - Action

    public enum Action: Sendable {
        // Lifecycle
        case task
        case refresh

        // Data loading
        case occurrencesResponse(TaskResult<[GoalOccurrence]>)
        case recommendationsResponse(TaskResult<[Goal]>)
        case waterProgressResponse(TaskResult<WaterProgress?>)

        // User interactions
        case occurrenceTapped(UUID)
        case completeTick(UUID)
        case skipOccurrence(UUID)
        case addGoalTapped
        case recommendationTapped(Goal)

        // Water tracking
        case addWaterMeasurement(Double)

        // Child features
        case goalEditor(PresentationAction<GoalEditorFeature.Action>)
        case occurrenceDetail(PresentationAction<OccurrenceDetailFeature.Action>)

        // Internal
        case completeTickResponse(UUID, TaskResult<Void>)
        case skipResponse(UUID, TaskResult<Void>)
    }

    // MARK: - Dependencies

    @Dependency(\.occurrenceRepository) var occurrenceRepository
    @Dependency(\.goalRepository) var goalRepository
    @Dependency(\.measurementRepository) var measurementRepository
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .task:
                state.isLoading = true
                state.error = nil

                return .run { [date = state.selectedDate] send in
                    // Fetch today's occurrences
                    await send(.occurrencesResponse(
                        TaskResult { try await occurrenceRepository.fetchOccurrences(for: date) }
                    ))

                    // Fetch recommendations (all active goals for now)
                    await send(.recommendationsResponse(
                        TaskResult { try await goalRepository.fetchAll() }
                    ))

                    // Water progress can be fetched if we have a water goal
                    // For now, skip water progress until we identify the water goal
                }

            case .refresh:
                return Effect.send(.task)

            // MARK: Data Responses

            case let .occurrencesResponse(.success(occurrences)):
                state.occurrences = IdentifiedArray(uniqueElements: occurrences)
                state.isLoading = false
                return .none

            case let .occurrencesResponse(.failure(error)):
                state.error = "Failed to load occurrences: \(error.localizedDescription)"
                state.isLoading = false
                return .none

            case let .recommendationsResponse(.success(goals)):
                state.recommendations = goals
                return .none

            case .recommendationsResponse(.failure):
                // Silent failure for recommendations
                return .none

            case let .waterProgressResponse(.success(progress)):
                state.waterProgress = progress
                if let waterGoalId = progress?.goalId {
                    return .run { send in
                        if let goal = try? await goalRepository.fetch(waterGoalId) {
                            // Could update state with water goal if needed
                        }
                    }
                }
                return .none

            case .waterProgressResponse(.failure):
                // Silent failure for water progress
                return .none

            // MARK: User Interactions

            case let .occurrenceTapped(id):
                guard let occurrence = state.occurrences[id: id] else {
                    return .none
                }
                state.occurrenceDetail = OccurrenceDetailFeature.State(occurrence: occurrence)
                return .none

            case let .completeTick(id):
                return .run { send in
                    await send(
                        .completeTickResponse(
                            id,
                            TaskResult { try await occurrenceRepository.completeTick(id) }
                        )
                    )
                }

            case let .completeTickResponse(id, .success):
                // Optimistically update UI
                state.occurrences[id: id]?.incrementCompletion()

                // Refresh to get server state
                return Effect.send(.refresh)
                    .debounce(id: CancelID.refresh, for: 0.5, scheduler: DispatchQueue.main)

            case let .completeTickResponse(_, .failure(error)):
                state.error = "Failed to complete: \(error.localizedDescription)"
                return .none

            case let .skipOccurrence(id):
                return .run { send in
                    await send(
                        .skipResponse(
                            id,
                            TaskResult { try await occurrenceRepository.skip(id, reason: nil) }
                        )
                    )
                }

            case let .skipResponse(id, .success):
                state.occurrences[id: id]?.markSkipped()
                return Effect.send(.refresh)
                    .debounce(id: CancelID.refresh, for: 0.5, scheduler: DispatchQueue.main)

            case let .skipResponse(_, .failure(error)):
                state.error = "Failed to skip: \(error.localizedDescription)"
                return .none

            case .addGoalTapped:
                state.goalEditor = GoalEditorFeature.State(mode: .create)
                return .none

            case let .recommendationTapped(goal):
                // Could show goal detail or quick-add
                return .none

            // MARK: Water Tracking

            case let .addWaterMeasurement(amount):
                guard let waterGoal = state.waterGoal else {
                    return .none
                }

                return .run { send in
                    _ = try await measurementRepository.addMeasurement(
                        for: waterGoal.id,
                        value: amount,
                        unit: .ml,
                        occurrenceId: nil
                    )
                    await send(.refresh)
                }

            // MARK: Child Features

            case .goalEditor(.presented(.delegate(.goalSaved))):
                state.goalEditor = nil
                return Effect.send(.refresh)

            case .goalEditor:
                return .none

            case .occurrenceDetail:
                return .none
            }
        }
        .ifLet(\.$goalEditor, action: \.goalEditor) {
            GoalEditorFeature()
        }
        .ifLet(\.$occurrenceDetail, action: \.occurrenceDetail) {
            OccurrenceDetailFeature()
        }
    }

    // MARK: - Cancel IDs

    private enum CancelID {
        case refresh
    }
}

// MARK: - Supporting Types

public struct WaterProgress: Equatable, Sendable {
    public var goalId: UUID
    public var consumed: Double
    public var target: Double
    public var unit: UnitKind

    public var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    public var isComplete: Bool {
        consumed >= target
    }

    public var remaining: Double {
        max(target - consumed, 0)
    }
}

public enum UnitKind: String, Codable, Sendable {
    case ml, l, oz, count, min

    public var displayName: String {
        switch self {
        case .ml: return "ml"
        case .l: return "L"
        case .oz: return "oz"
        case .count: return "count"
        case .min: return "min"
        }
    }
}

// MARK: - Placeholder Features (to be implemented)

@Reducer
public struct GoalEditorFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Mode { case create, edit(Goal) }
        public var mode: Mode
        public init(mode: Mode) { self.mode = mode }
    }

    public enum Action: Sendable {
        case delegate(Delegate)
        public enum Delegate: Sendable {
            case goalSaved(Goal)
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}

@Reducer
public struct OccurrenceDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var occurrence: GoalOccurrence
        public init(occurrence: GoalOccurrence) {
            self.occurrence = occurrence
        }
    }

    public enum Action: Sendable {
        case dismiss
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}
