import Foundation
import OSLog
import Supabase

/// Engine for synchronizing local cache with Supabase backend
///
/// Implements delta sync using `updated_at` timestamps.
/// Handles conflict resolution with last-write-wins strategy.
///
/// NOTE: Converted from @MainActor class to actor for performance.
/// Sync operations involve network/database work that should NOT block the main thread.
/// Actor provides thread safety without forcing main thread execution.
public actor SyncEngine {
    private let cacheService: CacheService
    private let supabaseClient: SupabaseClient

    // Last sync timestamps per entity type
    private var lastSyncTimestamps: [String: Date] = [:]

    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "com.habittracker.lastSync"

    // Concurrent sync protection
    private var isSyncing = false
    private var syncTask: Task<Void, Error>?

    /// MARK: - Initialization

    public init(cacheService: CacheService, supabaseClient: SupabaseClient) {
        self.cacheService = cacheService
        self.supabaseClient = supabaseClient

        // Load last sync timestamps
        if let data = userDefaults.data(forKey: lastSyncKey),
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: data) {
            self.lastSyncTimestamps = timestamps
        }
    }

    /// MARK: - Full Sync

    /// Performs a full bidirectional sync
    ///
    /// 1. Uploads pending local changes
    /// 2. Downloads updates from server
    /// 3. Updates cache sync state
    ///
    /// If a sync is already in progress, this will await the existing sync instead
    /// of starting a new one, preventing duplicate syncs and race conditions.
    ///
    /// - Parameter userId: The user ID to sync for
    /// - Throws: SyncError if sync fails
    public func performFullSync(userId: UUID) async throws {
        // If already syncing, await existing task
        if let existing = syncTask {
            return try await existing.value
        }

        guard !isSyncing else {
            throw SyncError.alreadySyncing
        }

        isSyncing = true
        defer { isSyncing = false }

        let task = Task {
            defer { syncTask = nil }

            // Upload pending changes first
            try await uploadPendingChanges(userId: userId)

            // Download updates from server
            try await downloadUpdates(userId: userId)

            // Save sync timestamps
            saveLastSyncTimestamps()
        }

        syncTask = task
        try await task.value
    }

    /// MARK: - Upload Pending Changes

    private func uploadPendingChanges(userId: UUID) async throws {
        // Upload pending areas
        try await uploadPendingAreas()

        // Upload pending goals
        try await uploadPendingGoals()

        // Upload pending occurrences
        try await uploadPendingOccurrences()

        // Upload pending measurements
        try await uploadPendingMeasurements()

        // Upload pending profiles
        try await uploadPendingProfiles()

        // Upload pending programs
        try await uploadPendingPrograms()

        // Upload pending reflections
        try await uploadPendingReflections()
    }

    private func uploadPendingAreas() async throws {
        let pending = try cacheService.fetchPendingAreas()

        for cached in pending {
            let area = cached.toDomain()

            do {
                let dto = AreaDTO(from: area)

                // Upsert to Supabase
                try await supabaseClient
                    .from("areas")
                    .upsert(dto)
                    .execute()

                // Update cache with synced state (let CacheService handle ModelContext)
                try cacheService.saveArea(area, syncState: .synced)
            } catch {
                // Update cache with failed state (let CacheService handle ModelContext)
                try? cacheService.saveArea(area, syncState: .failed)
                Logger.sync.error("Failed to sync area \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingGoals() async throws {
        let pending = try cacheService.fetchPendingGoals()

        for cached in pending {
            let goal = cached.toDomain()

            do {
                let dto = GoalDTO(from: goal)

                try await supabaseClient
                    .from("goals")
                    .upsert(dto)
                    .execute()

                // Update cache with synced state (let CacheService handle ModelContext)
                try cacheService.saveGoal(goal, syncState: .synced)
            } catch {
                // Update cache with failed state (let CacheService handle ModelContext)
                try? cacheService.saveGoal(goal, syncState: .failed)
                Logger.sync.error("Failed to sync goal \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingOccurrences() async throws {
        let pending = try cacheService.fetchPendingOccurrences()

        for cached in pending {
            let occurrence = cached.toDomain()

            do {
                let dto = GoalOccurrenceDTO(from: occurrence)

                try await supabaseClient
                    .from("goal_occurrences")
                    .upsert(dto)
                    .execute()

                // Update cache with synced state (let CacheService handle ModelContext)
                try cacheService.saveOccurrence(occurrence, syncState: .synced)
            } catch {
                // Update cache with failed state (let CacheService handle ModelContext)
                try? cacheService.saveOccurrence(occurrence, syncState: .failed)
                Logger.sync.error("Failed to sync occurrence \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingMeasurements() async throws {
        let pending = try cacheService.fetchPendingMeasurements()

        for cached in pending {
            let measurement = cached.toDomain()

            do {
                let dto = MeasurementDTO(from: measurement)

                try await supabaseClient
                    .from("measurements")
                    .upsert(dto)
                    .execute()

                // Update cache with synced state (let CacheService handle ModelContext)
                try cacheService.saveMeasurement(measurement, syncState: .synced)
            } catch {
                // Update cache with failed state (let CacheService handle ModelContext)
                try? cacheService.saveMeasurement(measurement, syncState: .failed)
                Logger.sync.error("Failed to sync measurement \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingProfiles() async throws {
        let pending = try cacheService.fetchPendingProfiles()

        for cached in pending {
            let profile = cached.toDomain()

            do {
                let dto = ProfileDTO(from: profile)

                try await supabaseClient
                    .from("profiles")
                    .upsert(dto)
                    .execute()

                try cacheService.saveProfile(profile, syncState: .synced)
            } catch {
                try? cacheService.saveProfile(profile, syncState: .failed)
                Logger.sync.error("Failed to sync profile \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingPrograms() async throws {
        let pending = try cacheService.fetchPendingPrograms()

        for cached in pending {
            let program = cached.toDomain()

            do {
                let dto = ProgramDTO(from: program)

                try await supabaseClient
                    .from("programs")
                    .upsert(dto)
                    .execute()

                try cacheService.saveProgram(program, syncState: .synced)
            } catch {
                try? cacheService.saveProgram(program, syncState: .failed)
                Logger.sync.error("Failed to sync program \(cached.id)", error: error)
            }
        }
    }

    private func uploadPendingReflections() async throws {
        let pending = try cacheService.fetchPendingReflections()

        for cached in pending {
            let reflection = cached.toDomain()

            do {
                let dto = ReflectionDTO(from: reflection)

                try await supabaseClient
                    .from("reflections")
                    .upsert(dto)
                    .execute()

                try cacheService.saveReflection(reflection, syncState: .synced)
            } catch {
                try? cacheService.saveReflection(reflection, syncState: .failed)
                Logger.sync.error("Failed to sync reflection \(cached.id)", error: error)
            }
        }
    }

    /// MARK: - Download Updates

    private func downloadUpdates(userId: UUID) async throws {
        // Download updated areas
        try await downloadAreas(userId: userId)

        // Download updated goals
        try await downloadGoals(userId: userId)

        // Download updated occurrences
        try await downloadOccurrences(userId: userId)

        // Download updated measurements
        try await downloadMeasurements(userId: userId)

        // Download updated profiles
        try await downloadProfiles(userId: userId)

        // Download updated programs
        try await downloadPrograms()

        // Download updated reflections
        try await downloadReflections(userId: userId)
    }

    private func downloadAreas(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["areas"] ?? Date.distantPast

        let dtos: [AreaDTO] = try await supabaseClient
            .from("areas")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let area = dto.toDomain
            try cacheService.saveArea(area, syncState: .synced)
        }

        lastSyncTimestamps["areas"] = Date()
    }

    private func downloadGoals(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["goals"] ?? Date.distantPast

        let dtos: [GoalDTO] = try await supabaseClient
            .from("goals")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let goal = dto.toDomain
            try cacheService.saveGoal(goal, syncState: .synced)
        }

        lastSyncTimestamps["goals"] = Date()
    }

    private func downloadOccurrences(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["occurrences"] ?? Date.distantPast

        // Only sync recent occurrences (last 30 days)
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            throw SyncError.dateCalculationFailed
        }

        let dtos: [GoalOccurrenceDTO] = try await supabaseClient
            .from("goal_occurrences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .gte("scheduled_date", value: thirtyDaysAgo.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let occurrence = dto.toDomain
            try cacheService.saveOccurrence(occurrence, syncState: .synced)
        }

        lastSyncTimestamps["occurrences"] = Date()
    }

    private func downloadMeasurements(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["measurements"] ?? Date.distantPast

        // Only sync recent measurements (last 90 days)
        guard let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else {
            throw SyncError.dateCalculationFailed
        }

        let dtos: [MeasurementDTO] = try await supabaseClient
            .from("measurements")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .gte("recorded_at", value: ninetyDaysAgo.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let measurement = dto.toDomain
            try cacheService.saveMeasurement(measurement, syncState: .synced)
        }

        lastSyncTimestamps["measurements"] = Date()
    }

    private func downloadProfiles(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["profiles"] ?? Date.distantPast

        let dtos: [ProfileDTO] = try await supabaseClient
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let profile = dto.toDomain
            try cacheService.saveProfile(profile, syncState: .synced)
        }

        lastSyncTimestamps["profiles"] = Date()
    }

    private func downloadPrograms() async throws {
        let lastSync = lastSyncTimestamps["programs"] ?? Date.distantPast

        // Download only public programs
        let dtos: [ProgramDTO] = try await supabaseClient
            .from("programs")
            .select()
            .eq("visibility", value: "public")
            .gt("updated_at", value: lastSync.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let program = dto.toDomain
            try cacheService.saveProgram(program, syncState: .synced)
        }

        lastSyncTimestamps["programs"] = Date()
    }

    private func downloadReflections(userId: UUID) async throws {
        let lastSync = lastSyncTimestamps["reflections"] ?? Date.distantPast

        // Only sync recent reflections (last 90 days)
        guard let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else {
            throw SyncError.dateCalculationFailed
        }

        let dtos: [ReflectionDTO] = try await supabaseClient
            .from("reflections")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gt("updated_at", value: lastSync.iso8601String)
            .gte("reflection_date", value: ninetyDaysAgo.iso8601String)
            .execute()
            .value

        for dto in dtos {
            let reflection = dto.toDomain
            try cacheService.saveReflection(reflection, syncState: .synced)
        }

        lastSyncTimestamps["reflections"] = Date()
    }

    /// MARK: - Conflict Resolution

    /// Resolves conflicts using last-write-wins strategy
    ///
    /// Compares `updated_at` timestamps and keeps the newer version.
    private func resolveConflict<T>(local: T, remote: T, localUpdatedAt: Date, remoteUpdatedAt: Date) -> T {
        // Last-write-wins: keep the version with newer updated_at
        return remoteUpdatedAt > localUpdatedAt ? remote : local
    }

    /// MARK: - Persistence

    private func saveLastSyncTimestamps() {
        if let data = try? JSONEncoder().encode(lastSyncTimestamps) {
            userDefaults.set(data, forKey: lastSyncKey)
        }
    }

    public func resetSyncState() {
        lastSyncTimestamps.removeAll()
        userDefaults.removeObject(forKey: lastSyncKey)
    }

    /// MARK: - Cleanup

    /// Clears old synced data to free up space
    ///
    /// Keeps pending changes and recent data (last 30 days).
    public func clearOldCachedData() throws {
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            throw SyncError.dateCalculationFailed
        }
        try cacheService.clearSyncedData(olderThan: thirtyDaysAgo)
    }
}

/// MARK: - SyncError

public enum SyncError: LocalizedError {
    case uploadFailed(String)
    case downloadFailed(String)
    case conflictResolutionFailed(String)
    case alreadySyncing
    case dateCalculationFailed

    public var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .conflictResolutionFailed(let message):
            return "Conflict resolution failed: \(message)"
        case .alreadySyncing:
            return "Sync already in progress"
        case .dateCalculationFailed:
            return "Date calculation failed - this should never happen"
        }
    }
}

/// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
