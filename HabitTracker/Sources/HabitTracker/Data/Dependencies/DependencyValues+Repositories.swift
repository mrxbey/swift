import ComposableArchitecture
import Foundation

/// MARK: - Repository Dependencies

extension DependencyValues {
    /// Repository for managing Area entities
    public var areaRepository: AreaRepository {
        get { self[AreaRepositoryKey.self] }
        set { self[AreaRepositoryKey.self] = newValue }
    }

    /// Repository for managing Goal entities
    public var goalRepository: GoalRepository {
        get { self[GoalRepositoryKey.self] }
        set { self[GoalRepositoryKey.self] = newValue }
    }

    /// Repository for managing GoalOccurrence entities
    public var occurrenceRepository: OccurrenceRepository {
        get { self[OccurrenceRepositoryKey.self] }
        set { self[OccurrenceRepositoryKey.self] = newValue }
    }

    /// Repository for managing Measurement entities
    public var measurementRepository: MeasurementRepository {
        get { self[MeasurementRepositoryKey.self] }
        set { self[MeasurementRepositoryKey.self] = newValue }
    }

    /// Repository for managing Reflection entities
    public var reflectionRepository: ReflectionRepository {
        get { self[ReflectionRepositoryKey.self] }
        set { self[ReflectionRepositoryKey.self] = newValue }
    }

    /// Repository for managing Program entities
    public var programRepository: ProgramRepository {
        get { self[ProgramRepositoryKey.self] }
        set { self[ProgramRepositoryKey.self] = newValue }
    }

    /// Service for calling Supabase RPCs
    public var rpcService: RPCService {
        get { self[RPCServiceKey.self] }
        set { self[RPCServiceKey.self] = newValue }
    }

    /// Service for Supabase Realtime subscriptions
    public var realtimeService: RealtimeService {
        get { self[RealtimeServiceKey.self] }
        set { self[RealtimeServiceKey.self] = newValue }
    }

    /// Service for local cache management
    public var cacheService: CacheService {
        get { self[CacheServiceKey.self] }
        set { self[CacheServiceKey.self] = newValue }
    }

    /// Engine for delta sync
    public var syncEngine: SyncEngine {
        get { self[SyncEngineKey.self] }
        set { self[SyncEngineKey.self] = newValue }
    }

    /// Coordinator for managing sync operations
    public var syncCoordinator: SyncCoordinator {
        get { self[SyncCoordinatorKey.self] }
        set { self[SyncCoordinatorKey.self] = newValue }
    }

    /// Monitor for network connectivity
    public var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}

/// MARK: - Dependency Keys

private enum AreaRepositoryKey: DependencyKey {
    static let liveValue: AreaRepository = SupabaseAreaRepository()

    static let testValue: AreaRepository = MockAreaRepository()

    static let previewValue: AreaRepository = MockAreaRepository()
}

private enum GoalRepositoryKey: DependencyKey {
    static let liveValue: GoalRepository = SupabaseGoalRepository()

    static let testValue: GoalRepository = MockGoalRepository()

    static let previewValue: GoalRepository = MockGoalRepository()
}

private enum OccurrenceRepositoryKey: DependencyKey {
    static let liveValue: OccurrenceRepository = SupabaseOccurrenceRepository()

    static let testValue: OccurrenceRepository = MockOccurrenceRepository()

    static let previewValue: OccurrenceRepository = MockOccurrenceRepository()
}

private enum MeasurementRepositoryKey: DependencyKey {
    static let liveValue: MeasurementRepository = SupabaseMeasurementRepository()

    static let testValue: MeasurementRepository = MockMeasurementRepository()

    static let previewValue: MeasurementRepository = MockMeasurementRepository()
}

private enum ReflectionRepositoryKey: DependencyKey {
    // Note: Cannot use async init in static property, so we create mock for now
    // In production, inject properly initialized repository
    static let liveValue: ReflectionRepository = MockReflectionRepository()

    static let testValue: ReflectionRepository = MockReflectionRepository()

    static let previewValue: ReflectionRepository = MockReflectionRepository()
}

private enum ProgramRepositoryKey: DependencyKey {
    // Note: Cannot use async init in static property, so we create mock for now
    // In production, inject properly initialized repository
    static let liveValue: ProgramRepository = MockProgramRepository()

    static let testValue: ProgramRepository = MockProgramRepository()

    static let previewValue: ProgramRepository = MockProgramRepository()
}

private enum RPCServiceKey: DependencyKey {
    static let liveValue: RPCService = RPCService()

    static let testValue: RPCService = RPCService()

    static let previewValue: RPCService = RPCService()
}

private enum RealtimeServiceKey: DependencyKey {
    static let liveValue: RealtimeService = RealtimeService()

    static let testValue: RealtimeService = RealtimeService()

    static let previewValue: RealtimeService = RealtimeService()
}

private enum CacheServiceKey: DependencyKey {
    static let liveValue: CacheService = {
        do {
            return try CacheService()
        } catch {
            fatalError("Failed to initialize CacheService: \(error)")
        }
    }()

    static let testValue: CacheService = {
        do {
            return try CacheService()
        } catch {
            fatalError("Failed to initialize test CacheService: \(error)")
        }
    }()

    static let previewValue: CacheService = {
        do {
            return try CacheService()
        } catch {
            fatalError("Failed to initialize preview CacheService: \(error)")
        }
    }()
}

private enum SyncEngineKey: DependencyKey {
    static let liveValue: SyncEngine = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            return SyncEngine(cacheService: cache, supabaseClient: client)
        } catch {
            fatalError("Failed to initialize SyncEngine: \(error)")
        }
    }()

    static let testValue: SyncEngine = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            return SyncEngine(cacheService: cache, supabaseClient: client)
        } catch {
            fatalError("Failed to initialize test SyncEngine: \(error)")
        }
    }()

    static let previewValue: SyncEngine = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            return SyncEngine(cacheService: cache, supabaseClient: client)
        } catch {
            fatalError("Failed to initialize preview SyncEngine: \(error)")
        }
    }()
}

private enum SyncCoordinatorKey: DependencyKey {
    static let liveValue: SyncCoordinator = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            let engine = SyncEngine(cacheService: cache, supabaseClient: client)
            let monitor = NetworkMonitor()
            return SyncCoordinator(cacheService: cache, syncEngine: engine, networkMonitor: monitor)
        } catch {
            fatalError("Failed to initialize SyncCoordinator: \(error)")
        }
    }()

    static let testValue: SyncCoordinator = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            let engine = SyncEngine(cacheService: cache, supabaseClient: client)
            let monitor = NetworkMonitor()
            return SyncCoordinator(cacheService: cache, syncEngine: engine, networkMonitor: monitor)
        } catch {
            fatalError("Failed to initialize test SyncCoordinator: \(error)")
        }
    }()

    static let previewValue: SyncCoordinator = {
        do {
            let cache = try CacheService()
            let client = SupabaseService.shared.getClient()
            let engine = SyncEngine(cacheService: cache, supabaseClient: client)
            let monitor = NetworkMonitor()
            return SyncCoordinator(cacheService: cache, syncEngine: engine, networkMonitor: monitor)
        } catch {
            fatalError("Failed to initialize preview SyncCoordinator: \(error)")
        }
    }()
}

private enum NetworkMonitorKey: DependencyKey {
    static let liveValue: NetworkMonitor = NetworkMonitor()

    static let testValue: NetworkMonitor = NetworkMonitor()

    static let previewValue: NetworkMonitor = NetworkMonitor()
}

/// MARK: - Mock Repositories

/// Mock implementation of AreaRepository for testing and previews
public actor MockAreaRepository: AreaRepository {
    private var areas: [UUID: Area] = [:]

    public init() {}

    public func fetchAll() async throws -> [Area] {
        Array(areas.values).sorted { $0.createdAt < $1.createdAt }
    }

    public func fetch(_ id: UUID) async throws -> Area {
        guard let area = areas[id] else {
            throw SupabaseError.notFound
        }
        return area
    }

    public func create(_ area: Area) async throws -> Area {
        areas[area.id] = area
        return area
    }

    public func update(_ area: Area) async throws {
        areas[area.id] = area
    }

    public func delete(id: UUID) async throws {
        areas.removeValue(forKey: id)
    }

    public func archive(id: UUID) async throws {
        if var area = areas[id] {
            area.status = .archived
            areas[id] = area
        }
    }

    public func fetchStatistics(for id: UUID) async throws -> AreaStatistics {
        AreaStatistics(
            areaId: id,
            activeGoalsCount: 5,
            completedGoalsCount: 10,
            totalPoints: 150,
            completionRate: 0.75,
            currentStreak: 7
        )
    }
}

/// Mock implementation of GoalRepository for testing and previews
public actor MockGoalRepository: GoalRepository {
    private var goals: [UUID: Goal] = [:]

    public init() {}

    public func fetchAll() async throws -> [Goal] {
        Array(goals.values).sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchGoals(for areaId: UUID) async throws -> [Goal] {
        goals.values.filter { $0.areaId == areaId }.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetch(_ id: UUID) async throws -> Goal {
        guard let goal = goals[id] else {
            throw SupabaseError.notFound
        }
        return goal
    }

    public func create(_ goal: Goal) async throws -> Goal {
        goals[goal.id] = goal
        return goal
    }

    public func update(_ goal: Goal) async throws {
        goals[goal.id] = goal
    }

    public func delete(id: UUID) async throws {
        goals.removeValue(forKey: id)
    }

    public func archive(id: UUID) async throws {
        if var goal = goals[id] {
            goal.status = .archived
            goals[id] = goal
        }
    }

    public func complete(id: UUID) async throws {
        if var goal = goals[id] {
            goal.status = .completed
            goals[id] = goal
        }
    }

    public func searchByHashtag(_ hashtag: String) async throws -> [Goal] {
        goals.values.filter { $0.hashtags.contains(hashtag) }
    }

    public func fetchMostCompleted(limit: Int, days: Int) async throws -> [GoalWithStats] {
        []
    }
}

/// Mock implementation of OccurrenceRepository for testing and previews
public actor MockOccurrenceRepository: OccurrenceRepository {
    private var occurrences: [UUID: GoalOccurrence] = [:]

    public init() {}

    public func fetchToday() async throws -> [GoalOccurrence] {
        let today = Date()
        let calendar = Calendar.current
        return occurrences.values.filter { occurrence in
            calendar.isDate(occurrence.scheduledDate, inSameDayAs: today)
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public func fetchOccurrences(for date: Date) async throws -> [GoalOccurrence] {
        let calendar = Calendar.current
        return occurrences.values.filter { occurrence in
            calendar.isDate(occurrence.scheduledDate, inSameDayAs: date)
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public func fetchOccurrences(from: Date, to: Date) async throws -> [GoalOccurrence] {
        occurrences.values.filter { occurrence in
            occurrence.scheduledDate >= from && occurrence.scheduledDate <= to
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    public func fetch(_ id: UUID) async throws -> GoalOccurrence {
        guard let occurrence = occurrences[id] else {
            throw SupabaseError.notFound
        }
        return occurrence
    }

    public func create(_ occurrence: GoalOccurrence) async throws -> GoalOccurrence {
        occurrences[occurrence.id] = occurrence
        return occurrence
    }

    public func update(_ occurrence: GoalOccurrence) async throws {
        occurrences[occurrence.id] = occurrence
    }

    public func completeTick(_ id: UUID) async throws {
        if var occurrence = occurrences[id] {
            occurrence.completedCount += 1
            if occurrence.completedCount >= occurrence.targetCount {
                occurrence.status = .completed
            }
            // Note: GoalOccurrence doesn't have lastCompletedAt field - removed
            occurrences[id] = occurrence
        }
    }

    public func skip(_ id: UUID, reason: String?) async throws {
        if var occurrence = occurrences[id] {
            occurrence.status = .skipped
            occurrences[id] = occurrence
        }
    }

    public func rename(_ id: UUID, to newName: String) async throws {
        if var occurrence = occurrences[id] {
            occurrence.nameOverride = newName  // Fixed: was renameOverride
            occurrences[id] = occurrence
        }
    }

    public func ensureOccurrence(for goalId: UUID, on date: Date) async throws -> GoalOccurrence {
        // Find existing or create new
        let existing = occurrences.values.first { occurrence in
            occurrence.goalId == goalId &&
            Calendar.current.isDate(occurrence.scheduledDate, inSameDayAs: date)
        }

        if let existing = existing {
            return existing
        }

        let newOccurrence = GoalOccurrence(
            id: UUID(),
            goalId: goalId,
            userId: UUID(),
            scheduledDate: date,
            dueAt: nil,
            status: .pending,
            targetCount: 1,
            completedCount: 0,
            keepUntilComplete: false,
            rolledFromId: nil,
            rolledIntoId: nil,
            nameOverride: nil,  // Fixed: was renameOverride
            emojiOverride: nil,
            contentSnapshot: nil,
            isOneTime: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        occurrences[newOccurrence.id] = newOccurrence
        return newOccurrence
    }
}

/// Mock implementation of MeasurementRepository for testing and previews
public actor MockMeasurementRepository: MeasurementRepository {
    private var measurements: [UUID: Measurement] = [:]

    public init() {}

    public func fetchMeasurements(for goalId: UUID) async throws -> [Measurement] {
        measurements.values.filter { $0.goalId == goalId }.sorted { $0.recordedAt > $1.recordedAt }
    }

    public func fetchMeasurements(for goalId: UUID, from: Date, to: Date) async throws -> [Measurement] {
        measurements.values.filter {
            $0.goalId == goalId && $0.recordedAt >= from && $0.recordedAt <= to
        }.sorted { $0.recordedAt < $1.recordedAt }
    }

    public func fetch(_ id: UUID) async throws -> Measurement {
        guard let measurement = measurements[id] else {
            throw SupabaseError.notFound
        }
        return measurement
    }

    public func create(_ measurement: Measurement) async throws -> Measurement {
        measurements[measurement.id] = measurement
        return measurement
    }

    public func update(_ measurement: Measurement) async throws {
        measurements[measurement.id] = measurement
    }

    public func delete(id: UUID) async throws {
        measurements.removeValue(forKey: id)
    }

    public func addMeasurement(
        for goalId: UUID,
        value: Double,
        unit: UnitKind,
        occurrenceId: UUID?
    ) async throws -> Measurement {
        let measurement = Measurement(
            id: UUID(),
            userId: UUID(),
            goalId: goalId,
            occurrenceId: occurrenceId,
            value: value,
            unit: unit,
            recordedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        measurements[measurement.id] = measurement
        return measurement
    }

    public func fetchWaterProgress(
        for goalId: UUID,
        from: Date,
        to: Date
    ) async throws -> [WaterDataPoint] {
        []
    }

    public func setMeasureTarget(
        for goalId: UUID,
        targetValue: Double,
        unit: UnitKind,
        effectiveFrom: Date
    ) async throws -> GoalMeasureTarget {
        GoalMeasureTarget(
            id: UUID(),
            userId: UUID(),
            goalId: goalId,
            targetValue: targetValue,
            unit: unit,
            effectiveFrom: effectiveFrom,
            effectiveTo: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Mock implementation of ReflectionRepository for testing and previews
public actor MockReflectionRepository: ReflectionRepository {
    private var reflections: [UUID: Reflection] = [:]

    public init() {}

    public func fetchAll() async throws -> [Reflection] {
        Array(reflections.values).sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetchReflections(for goalId: UUID) async throws -> [Reflection] {
        reflections.values.filter { $0.goalId == goalId }.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetchReflections(forArea areaId: UUID) async throws -> [Reflection] {
        reflections.values.filter { $0.areaId == areaId }.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetchReflections(from startDate: Date, to endDate: Date) async throws -> [Reflection] {
        reflections.values.filter {
            $0.reflectionDate >= startDate && $0.reflectionDate <= endDate
        }.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetchReflections(withMood mood: ReflectionMood) async throws -> [Reflection] {
        reflections.values.filter { $0.mood == mood }.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetchReflections(withTag tag: String) async throws -> [Reflection] {
        reflections.values.filter { $0.tags.contains(tag) }.sorted { $0.reflectionDate > $1.reflectionDate }
    }

    public func fetch(_ id: UUID) async throws -> Reflection {
        guard let reflection = reflections[id] else {
            throw SupabaseError.notFound
        }
        return reflection
    }

    public func create(_ reflection: Reflection) async throws -> Reflection {
        reflections[reflection.id] = reflection
        return reflection
    }

    public func update(_ reflection: Reflection) async throws {
        reflections[reflection.id] = reflection
    }

    public func delete(id: UUID) async throws {
        reflections.removeValue(forKey: id)
    }

    public func search(query: String) async throws -> [Reflection] {
        reflections.values.filter {
            $0.content.localizedCaseInsensitiveContains(query)
        }.sorted { $0.reflectionDate > $1.reflectionDate }
    }
}

/// Mock implementation of ProgramRepository for testing and previews
public actor MockProgramRepository: ProgramRepository {
    private var programs: [UUID: Program] = [:]
    private var programGoals: [UUID: [ProgramGoal]] = [:]

    public init() {
        // Add some sample programs for testing
        let sampleProgram = Program(
            id: UUID(),
            title: "Morning Routine",
            description: "Start your day right with these essential habits",
            emoji: "☀️",
            imageURL: nil,
            category: .productivity,
            difficulty: .beginner,
            durationDays: 21,
            tags: ["morning", "routine", "productivity"],
            authorName: "HabitTracker Team",
            isOfficial: true,
            isPublished: true
        )
        programs[sampleProgram.id] = sampleProgram

        // Add sample goals for this program
        programGoals[sampleProgram.id] = [
            ProgramGoal(
                id: UUID(),
                programId: sampleProgram.id,
                title: "Morning Meditation",
                emoji: "🧘",
                kind: "habit",
                timesPerDay: 1,
                schedulePattern: "daily",
                orderIndex: 0
            ),
            ProgramGoal(
                id: UUID(),
                programId: sampleProgram.id,
                title: "Drink Water",
                emoji: "💧",
                kind: "habit",
                timesPerDay: 1,
                schedulePattern: "daily",
                orderIndex: 1
            )
        ]
    }

    public func fetchAll() async throws -> [Program] {
        Array(programs.values).sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchOfficialPrograms() async throws -> [Program] {
        programs.values.filter { $0.isOfficial }.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchPrograms(by category: ProgramCategory) async throws -> [Program] {
        programs.values.filter { $0.category == category }.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchPrograms(byDifficulty difficulty: ProgramDifficulty) async throws -> [Program] {
        programs.values.filter { $0.difficulty == difficulty }.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetchPrograms(withTag tag: String) async throws -> [Program] {
        programs.values.filter { $0.tags.contains(tag) }.sorted { $0.createdAt > $1.createdAt }
    }

    public func fetch(_ id: UUID) async throws -> Program {
        guard let program = programs[id] else {
            throw SupabaseError.notFound
        }
        return program
    }

    public func fetchGoals(for programId: UUID) async throws -> [ProgramGoal] {
        programGoals[programId] ?? []
    }

    public func adoptProgram(programId: UUID, areaId: UUID) async throws -> [Goal] {
        let goals = programGoals[programId] ?? []
        return goals.map { programGoal in
            Goal(
                id: UUID(),
                userId: UUID(),
                areaId: areaId,
                title: programGoal.title,
                emoji: programGoal.emoji,
                kind: .habit,
                status: .active,
                keepUntilComplete: false,
                timesPerDay: programGoal.timesPerDay,
                pointsPerCompletion: 10,
                linkedExerciseKey: nil,
                hashtags: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    public func search(query: String) async throws -> [Program] {
        programs.values.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    public func create(_ program: Program) async throws -> Program {
        programs[program.id] = program
        return program
    }

    public func update(_ program: Program) async throws {
        programs[program.id] = program
    }

    public func delete(id: UUID) async throws {
        programs.removeValue(forKey: id)
        programGoals.removeValue(forKey: id)
    }
}
