import Foundation
import SwiftData

/// Service for managing local cache with SwiftData
///
/// Provides thread-safe access to cached entities with sync state tracking.
/// Supports offline-first operations with pending change queues.
///
/// IMPORTANT: This service uses a background ModelContext and should NOT be called
/// from the main thread. All database operations run on a background thread to
/// prevent UI blocking and ANR (Application Not Responding) errors.
public final class CacheService: @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    /// MARK: - Initialization

    public init() throws {
        let schema = Schema([
            CachedArea.self,
            CachedGoal.self,
            CachedOccurrence.self,
            CachedMeasurement.self,
            CachedProfile.self,
            CachedProgram.self,
            CachedReflection.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        // Create background context for non-blocking operations
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    /// MARK: - Area Operations

    public func saveArea(_ area: Area, syncState: SyncState = .synced) throws {
        // Check if already exists
        let descriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { $0.id == area.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: area, syncState: syncState)
        } else {
            let cached = CachedArea(from: area, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchAreas(userId: UUID) throws -> [Area] {
        let descriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchArea(id: UUID) throws -> Area? {
        let descriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteArea(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Goal Operations

    public func saveGoal(_ goal: Goal, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.id == goal.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: goal, syncState: syncState)
        } else {
            let cached = CachedGoal(from: goal, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchGoals(userId: UUID) throws -> [Goal] {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchGoals(areaId: UUID) throws -> [Goal] {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.areaId == areaId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchGoal(id: UUID) throws -> Goal? {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteGoal(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Occurrence Operations

    public func saveOccurrence(_ occurrence: GoalOccurrence, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { $0.id == occurrence.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: occurrence, syncState: syncState)
        } else {
            let cached = CachedOccurrence(from: occurrence, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchOccurrences(userId: UUID, date: Date) throws -> [GoalOccurrence] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw CacheError.dateCalculationFailed
        }

        let descriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.userId == userId &&
                occurrence.scheduledDate >= startOfDay &&
                occurrence.scheduledDate < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchOccurrence(id: UUID) throws -> GoalOccurrence? {
        let descriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteOccurrence(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Measurement Operations

    public func saveMeasurement(_ measurement: Measurement, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { $0.id == measurement.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: measurement, syncState: syncState)
        } else {
            let cached = CachedMeasurement(from: measurement, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchMeasurements(goalId: UUID) throws -> [Measurement] {
        let descriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { $0.goalId == goalId },
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchMeasurement(id: UUID) throws -> Measurement? {
        let descriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { $0.id == id }
        )

        let cached = try modelContext.fetch(descriptor).first
        return cached?.toDomain()
    }

    public func deleteMeasurement(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Profile Operations

    public func saveProfile(_ profile: Profile, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedProfile>(
            predicate: #Predicate { $0.id == profile.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: profile, syncState: syncState)
        } else {
            let cached = CachedProfile(from: profile, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchProfile(userId: UUID) throws -> Profile? {
        let descriptor = FetchDescriptor<CachedProfile>(
            predicate: #Predicate { $0.id == userId }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteProfile(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedProfile>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Program Operations

    public func saveProgram(_ program: Program, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedProgram>(
            predicate: #Predicate { $0.id == program.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: program, syncState: syncState)
        } else {
            let cached = CachedProgram(from: program, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchPrograms() throws -> [Program] {
        let descriptor = FetchDescriptor<CachedProgram>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchProgram(id: UUID) throws -> Program? {
        let descriptor = FetchDescriptor<CachedProgram>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteProgram(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedProgram>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Reflection Operations

    public func saveReflection(_ reflection: Reflection, syncState: SyncState = .synced) throws {
        let descriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { $0.id == reflection.id }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: reflection, syncState: syncState)
        } else {
            let cached = CachedReflection(from: reflection, syncState: syncState)
            modelContext.insert(cached)
        }

        try modelContext.save()
    }

    public func fetchReflections(userId: UUID) throws -> [Reflection] {
        let descriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.reflectionDate, order: .reverse)]
        )

        let cached = try modelContext.fetch(descriptor)
        return cached.map { $0.toDomain() }
    }

    public func fetchReflection(id: UUID) throws -> Reflection? {
        let descriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func deleteReflection(id: UUID) throws {
        let descriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { $0.id == id }
        )

        if let cached = try modelContext.fetch(descriptor).first {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }

    /// MARK: - Sync State Management

    public func fetchPendingAreas() throws -> [CachedArea] {
        let descriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingGoals() throws -> [CachedGoal] {
        let descriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingOccurrences() throws -> [CachedOccurrence] {
        let descriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingMeasurements() throws -> [CachedMeasurement] {
        let descriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingProfiles() throws -> [CachedProfile] {
        let descriptor = FetchDescriptor<CachedProfile>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingPrograms() throws -> [CachedProgram] {
        let descriptor = FetchDescriptor<CachedProgram>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    public func fetchPendingReflections() throws -> [CachedReflection] {
        let descriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { $0.syncState == "pending" }
        )

        return try modelContext.fetch(descriptor)
    }

    /// MARK: - Clear Cache

    public func clearAll() throws {
        try modelContext.delete(model: CachedArea.self)
        try modelContext.delete(model: CachedGoal.self)
        try modelContext.delete(model: CachedOccurrence.self)
        try modelContext.delete(model: CachedMeasurement.self)
        try modelContext.delete(model: CachedProfile.self)
        try modelContext.delete(model: CachedProgram.self)
        try modelContext.delete(model: CachedReflection.self)
        try modelContext.save()
    }

    public func clearSyncedData(olderThan date: Date) throws {
        // Areas - using nil coalescing to avoid force unwrap
        // If lastSyncedAt is nil, it becomes .distantFuture which is always > date
        let areaDescriptor = FetchDescriptor<CachedArea>(
            predicate: #Predicate { area in
                area.syncState == "synced" &&
                (area.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldAreas = try modelContext.fetch(areaDescriptor)
        oldAreas.forEach { modelContext.delete($0) }

        // Goals
        let goalDescriptor = FetchDescriptor<CachedGoal>(
            predicate: #Predicate { goal in
                goal.syncState == "synced" &&
                (goal.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldGoals = try modelContext.fetch(goalDescriptor)
        oldGoals.forEach { modelContext.delete($0) }

        // Occurrences
        let occurrenceDescriptor = FetchDescriptor<CachedOccurrence>(
            predicate: #Predicate { occurrence in
                occurrence.syncState == "synced" &&
                (occurrence.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldOccurrences = try modelContext.fetch(occurrenceDescriptor)
        oldOccurrences.forEach { modelContext.delete($0) }

        // Measurements
        let measurementDescriptor = FetchDescriptor<CachedMeasurement>(
            predicate: #Predicate { measurement in
                measurement.syncState == "synced" &&
                (measurement.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldMeasurements = try modelContext.fetch(measurementDescriptor)
        oldMeasurements.forEach { modelContext.delete($0) }

        // Profiles
        let profileDescriptor = FetchDescriptor<CachedProfile>(
            predicate: #Predicate { profile in
                profile.syncState == "synced" &&
                (profile.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldProfiles = try modelContext.fetch(profileDescriptor)
        oldProfiles.forEach { modelContext.delete($0) }

        // Programs
        let programDescriptor = FetchDescriptor<CachedProgram>(
            predicate: #Predicate { program in
                program.syncState == "synced" &&
                (program.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldPrograms = try modelContext.fetch(programDescriptor)
        oldPrograms.forEach { modelContext.delete($0) }

        // Reflections
        let reflectionDescriptor = FetchDescriptor<CachedReflection>(
            predicate: #Predicate { reflection in
                reflection.syncState == "synced" &&
                (reflection.lastSyncedAt ?? .distantFuture) < date
            }
        )
        let oldReflections = try modelContext.fetch(reflectionDescriptor)
        oldReflections.forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}

/// MARK: - CacheError

public enum CacheError: LocalizedError {
    case dateCalculationFailed

    public var errorDescription: String? {
        switch self {
        case .dateCalculationFailed:
            return "Date calculation failed - this should never happen"
        }
    }
}
