import ComposableArchitecture
import Foundation

/// Feature for the Today screen - shows today's occurrences and recommendations
@Reducer
public struct TodayFeature {

    /// MARK: - State

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

    /// MARK: - Action

    public enum Action: Sendable {
        // Lifecycle
        case task
        case refresh

        // Data loading
        case occurrencesResponse(TaskResult<[GoalOccurrence]>)
        case recommendationsResponse(TaskResult<[Goal]>)
        case waterProgressResponse(TaskResult<WaterProgress?>)

        // Realtime
        case realtimeOccurrenceEvent(OccurrenceEvent)

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

    /// MARK: - Dependencies

    @Dependency(\.occurrenceRepository) var occurrenceRepository
    @Dependency(\.goalRepository) var goalRepository
    @Dependency(\.measurementRepository) var measurementRepository
    @Dependency(\.realtimeService) var realtimeService
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    /// MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            /// MARK: Lifecycle

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

                    // Subscribe to realtime occurrence updates
                    // Get userId from first occurrence or goal
                    if let userId = try? await goalRepository.fetchAll().first?.userId {
                        for await event in await realtimeService.subscribeToOccurrences(userId: userId) {
                            await send(.realtimeOccurrenceEvent(event))
                        }
                    }
                }

            case .refresh:
                return Effect.send(.task)

            /// MARK: Data Responses

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

            /// MARK: Realtime Events

            case let .realtimeOccurrenceEvent(.inserted(occurrence)):
                // Add new occurrence if it's for today
                let calendar = calendar
                if calendar.isDate(occurrence.scheduledDate, inSameDayAs: state.selectedDate) {
                    state.occurrences.append(occurrence)
                }
                return .none

            case let .realtimeOccurrenceEvent(.updated(occurrence)):
                // Update existing occurrence with server state
                // Handle conflict: server always wins for realtime events
                if state.occurrences[id: occurrence.id] != nil {
                    state.occurrences[id: occurrence.id] = occurrence
                }
                return .none

            case let .realtimeOccurrenceEvent(.deleted(id)):
                // Remove deleted occurrence
                state.occurrences.remove(id: id)
                return .none

            /// MARK: User Interactions

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
                // Optimistically update UI - using value semantics for TCA
                if var occurrence = state.occurrences[id: id] {
                    // Increment completion count
                    if occurrence.completedCount < occurrence.targetCount {
                        occurrence.completedCount += 1
                        if occurrence.completedCount >= occurrence.targetCount {
                            occurrence.status = .completed
                        }
                    }
                    // Assign modified copy back
                    state.occurrences[id: id] = occurrence
                }

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
                // Update occurrence status - using value semantics for TCA
                if var occurrence = state.occurrences[id: id] {
                    occurrence.status = .skipped
                    // Assign modified copy back
                    state.occurrences[id: id] = occurrence
                }
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

            /// MARK: Water Tracking

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

            /// MARK: Child Features

            case .goalEditor(.presented(.delegate(.goalSaved(_)))):
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

    /// MARK: - Cancel IDs

    private enum CancelID {
        case refresh
    }
}

/// MARK: - Supporting Types

public struct WaterProgress: Equatable, Sendable {
    public var goalId: UUID
    public var consumed: Double
    public var target: Double
    public var unit: Measurement.UnitKind  // Use domain model UnitKind

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

/// MARK: - Placeholder Features (to be implemented)

@Reducer
public struct GoalEditorFeature {

    /// MARK: - State

    @ObservableState
    public struct State: Equatable {
        public enum Mode: Equatable {
            case create
            case edit(Goal)

            public var editingGoal: Goal? {
                if case .edit(let goal) = self {
                    return goal
                }
                return nil
            }

            public var isEditing: Bool {
                if case .edit = self {
                    return true
                }
                return false
            }
        }

        // Mode
        public var mode: Mode

        // Form fields
        public var title: String
        public var emoji: String?
        public var areaId: UUID?
        public var kind: GoalKind
        public var timesPerDay: Int
        public var pointsPerCompletion: Int
        public var linkedExerciseKey: LinkedExercise?
        public var keepUntilComplete: Bool
        public var hashtags: [String]

        // UI state
        public var availableAreas: [Area] = []
        public var isLoadingAreas: Bool = false
        public var isSaving: Bool = false
        public var errorMessage: String?

        // Validation
        public var isValid: Bool {
            !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            title.count <= 100 &&
            areaId != nil &&
            pointsPerCompletion > 0 &&
            timesPerDay > 0 &&
            timesPerDay <= 100
        }

        public var canSave: Bool {
            isValid && !isSaving
        }

        public init(mode: Mode) {
            self.mode = mode

            // Initialize from mode
            if case .edit(let goal) = mode {
                self.title = goal.title
                self.emoji = goal.emoji
                self.areaId = goal.areaId
                self.kind = goal.kind
                self.timesPerDay = goal.timesPerDay
                self.pointsPerCompletion = goal.pointsPerCompletion
                self.linkedExerciseKey = goal.linkedExerciseKey
                self.keepUntilComplete = goal.keepUntilComplete
                self.hashtags = goal.hashtags
            } else {
                self.title = ""
                self.emoji = nil
                self.areaId = nil
                self.kind = .habit
                self.timesPerDay = 1
                self.pointsPerCompletion = 5
                self.linkedExerciseKey = nil
                self.keepUntilComplete = false
                self.hashtags = []
            }
        }
    }

    /// MARK: - Action

    public enum Action: Sendable {
        // Lifecycle
        case task
        case areasLoaded(TaskResult<[Area]>)

        // Form changes
        case titleChanged(String)
        case emojiChanged(String?)
        case areaSelected(UUID)
        case kindSelected(GoalKind)
        case timesPerDayChanged(Int)
        case pointsChanged(Int)
        case linkedExerciseKeySelected(LinkedExercise?)
        case keepUntilCompleteToggled

        // Actions
        case saveTapped
        case saveResponse(TaskResult<Goal>)
        case cancelTapped

        // Delegate
        case delegate(Delegate)

        public enum Delegate: Sendable {
            case goalSaved(Goal)
        }
    }

    /// MARK: - Dependencies

    @Dependency(\.goalRepository) var goalRepository
    @Dependency(\.areaRepository) var areaRepository
    @Dependency(\.authService) var authService
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid

    /// MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            /// MARK: Lifecycle

            case .task:
                state.isLoadingAreas = true
                return .run { send in
                    await send(.areasLoaded(
                        TaskResult { try await areaRepository.fetchAll() }
                    ))
                }

            case let .areasLoaded(.success(areas)):
                state.availableAreas = areas.filter { $0.status == .active }
                state.isLoadingAreas = false

                // Auto-select first area if creating and none selected
                if case .create = state.mode, state.areaId == nil, let firstArea = state.availableAreas.first {
                    state.areaId = firstArea.id
                }
                return .none

            case .areasLoaded(.failure):
                state.isLoadingAreas = false
                state.errorMessage = "Failed to load areas"
                return .none

            /// MARK: Form Changes

            case let .titleChanged(newTitle):
                state.title = String(newTitle.prefix(100)) // Enforce max length
                state.errorMessage = nil
                return .none

            case let .emojiChanged(newEmoji):
                state.emoji = newEmoji
                return .none

            case let .areaSelected(areaId):
                state.areaId = areaId
                state.errorMessage = nil
                return .none

            case let .kindSelected(kind):
                state.kind = kind

                // Auto-select linked exercise based on kind
                if kind == .measure && state.linkedExerciseKey == nil {
                    state.linkedExerciseKey = .water
                }
                return .none

            case let .timesPerDayChanged(times):
                state.timesPerDay = min(max(times, 1), 100) // Enforce 1-100 constraint
                return .none

            case let .pointsChanged(points):
                state.pointsPerCompletion = max(points, 0) // Enforce non-negative
                return .none

            case let .linkedExerciseKeySelected(key):
                state.linkedExerciseKey = key
                return .none

            case .keepUntilCompleteToggled:
                state.keepUntilComplete.toggle()
                return .none

            /// MARK: Actions

            case .saveTapped:
                guard state.isValid else {
                    if state.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        state.errorMessage = "Title cannot be empty"
                    } else if state.title.count > 100 {
                        state.errorMessage = "Title must be 100 characters or less"
                    } else if state.areaId == nil {
                        state.errorMessage = "Please select an area"
                    } else if state.pointsPerCompletion <= 0 {
                        state.errorMessage = "Points must be greater than 0"
                    } else if state.timesPerDay <= 0 || state.timesPerDay > 100 {
                        state.errorMessage = "Times per day must be between 1 and 100"
                    }
                    return .none
                }

                guard let areaId = state.areaId else {
                    state.errorMessage = "Please select an area"
                    return .none
                }

                state.isSaving = true
                state.errorMessage = nil

                return .run { [state] send in
                    await send(.saveResponse(
                        TaskResult {
                            let trimmedTitle = state.title.trimmingCharacters(in: .whitespaces)

                            if case .edit(let existingGoal) = state.mode {
                                // Update existing goal
                                var updatedGoal = existingGoal
                                updatedGoal.title = trimmedTitle
                                updatedGoal.emoji = state.emoji
                                updatedGoal.areaId = areaId
                                updatedGoal.kind = state.kind
                                updatedGoal.timesPerDay = state.timesPerDay
                                updatedGoal.pointsPerCompletion = state.pointsPerCompletion
                                updatedGoal.linkedExerciseKey = state.linkedExerciseKey
                                updatedGoal.keepUntilComplete = state.keepUntilComplete
                                updatedGoal.hashtags = state.hashtags
                                updatedGoal.updatedAt = Date()

                                try await goalRepository.update(updatedGoal)
                                return updatedGoal
                            } else {
                                // Create new goal - get userId from auth
                                guard let currentUser = await authService.currentUser() else {
                                    throw AuthError.noUserSession
                                }

                                let newGoal = Goal(
                                    id: uuid(),
                                    userId: currentUser.id,
                                    areaId: areaId,
                                    title: trimmedTitle,
                                    emoji: state.emoji,
                                    kind: state.kind,
                                    status: .active,
                                    keepUntilComplete: state.keepUntilComplete,
                                    timesPerDay: state.timesPerDay,
                                    pointsPerCompletion: state.pointsPerCompletion,
                                    linkedExerciseKey: state.linkedExerciseKey,
                                    hashtags: state.hashtags,
                                    createdAt: Date(),
                                    updatedAt: Date()
                                )

                                return try await goalRepository.create(newGoal)
                            }
                        }
                    ))
                }

            case let .saveResponse(.success(goal)):
                state.isSaving = false
                return .run { send in
                    await send(.delegate(.goalSaved(goal)))
                    await dismiss()
                }

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = "Failed to save goal: \(error.localizedDescription)"
                return .none

            case .cancelTapped:
                return .run { _ in
                    await dismiss()
                }

            case .delegate:
                return .none
            }
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
