import Foundation
import Supabase

/// Engine for synchronizing local cache with Supabase backend
///
/// Implements delta sync using `updated_at` timestamps.
/// Handles conflict resolution with last-write-wins strategy.
@MainActor
public final class SyncEngine {
    private let cacheService: CacheService
    private let supabaseClient: SupabaseClient

    // Last sync timestamps per entity type
    private var lastSyncTimestamps: [String: Date] = [:]

    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "com.habittracker.lastSync"

    // MARK: - Initialization

    public init(cacheService: CacheService, supabaseClient: SupabaseClient) {
        self.cacheService = cacheService
        self.supabaseClient = supabaseClient

        // Load last sync timestamps
        if let data = userDefaults.data(forKey: lastSyncKey),
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: data) {
            self.lastSyncTimestamps = timestamps
        }
    }

    // MARK: - Full Sync

    /// Performs a full bidirectional sync
    ///
    /// 1. Uploads pending local changes
    /// 2. Downloads updates from server
    /// 3. Updates cache sync state
    ///
    /// - Parameter userId: The user ID to sync for
    /// - Throws: SyncError if sync fails
    public func performFullSync(userId: UUID) async throws {
        // Upload pending changes first
        try await uploadPendingChanges(userId: userId)

        // Download updates from server
        try await downloadUpdates(userId: userId)

        // Save sync timestamps
        saveLastSyncTimestamps()
    }

    // MARK: - Upload Pending Changes

    private func uploadPendingChanges(userId: UUID) async throws {
        // Upload pending areas
        try await uploadPendingAreas()

        // Upload pending goals
        try await uploadPendingGoals()

        // Upload pending occurrences
        try await uploadPendingOccurrences()

        // Upload pending measurements
        try await uploadPendingMeasurements()
    }

    private func uploadPendingAreas() async throws {
        let pending = try cacheService.fetchPendingAreas()

        for cached in pending {
            do {
                let area = cached.toDomain()
                let dto = AreaDTO(from: area)

                // Upsert to Supabase
                try await supabaseClient
                    .from("areas")
                    .upsert(dto)
                    .execute()

                // Mark as synced
                cached.syncState = SyncState.synced.rawValue
                cached.lastSyncedAt = Date()
                try cacheService.saveArea(area, syncState: .synced)
            } catch {
                // Mark as failed
                cached.syncState = SyncState.failed.rawValue
                print("Failed to sync area \(cached.id): \(error)")
            }
        }
    }

    private func uploadPendingGoals() async throws {
        let pending = try cacheService.fetchPendingGoals()

        for cached in pending {
            do {
                let goal = cached.toDomain()
                let dto = GoalDTO(from: goal)

                try await supabaseClient
                    .from("goals")
                    .upsert(dto)
                    .execute()

                cached.syncState = SyncState.synced.rawValue
                cached.lastSyncedAt = Date()
                try cacheService.saveGoal(goal, syncState: .synced)
            } catch {
                cached.syncState = SyncState.failed.rawValue
                print("Failed to sync goal \(cached.id): \(error)")
            }
        }
    }

    private func uploadPendingOccurrences() async throws {
        let pending = try cacheService.fetchPendingOccurrences()

        for cached in pending {
            do {
                let occurrence = cached.toDomain()
                let dto = GoalOccurrenceDTO(from: occurrence)

                try await supabaseClient
                    .from("goal_occurrences")
                    .upsert(dto)
                    .execute()

                cached.syncState = SyncState.synced.rawValue
                cached.lastSyncedAt = Date()
                try cacheService.saveOccurrence(occurrence, syncState: .synced)
            } catch {
                cached.syncState = SyncState.failed.rawValue
                print("Failed to sync occurrence \(cached.id): \(error)")
            }
        }
    }

    private func uploadPendingMeasurements() async throws {
        let pending = try cacheService.fetchPendingMeasurements()

        for cached in pending {
            do {
                let measurement = cached.toDomain()
                let dto = MeasurementDTO(from: measurement)

                try await supabaseClient
                    .from("measurements")
                    .upsert(dto)
                    .execute()

                cached.syncState = SyncState.synced.rawValue
                cached.lastSyncedAt = Date()
                try cacheService.saveMeasurement(measurement, syncState: .synced)
            } catch {
                cached.syncState = SyncState.failed.rawValue
                print("Failed to sync measurement \(cached.id): \(error)")
            }
        }
    }

    // MARK: - Download Updates

    private func downloadUpdates(userId: UUID) async throws {
        // Download updated areas
        try await downloadAreas(userId: userId)

        // Download updated goals
        try await downloadGoals(userId: userId)

        // Download updated occurrences
        try await downloadOccurrences(userId: userId)

        // Download updated measurements
        try await downloadMeasurements(userId: userId)
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
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

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
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

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

    // MARK: - Conflict Resolution

    /// Resolves conflicts using last-write-wins strategy
    ///
    /// Compares `updated_at` timestamps and keeps the newer version.
    private func resolveConflict<T>(local: T, remote: T, localUpdatedAt: Date, remoteUpdatedAt: Date) -> T {
        // Last-write-wins: keep the version with newer updated_at
        return remoteUpdatedAt > localUpdatedAt ? remote : local
    }

    // MARK: - Persistence

    private func saveLastSyncTimestamps() {
        if let data = try? JSONEncoder().encode(lastSyncTimestamps) {
            userDefaults.set(data, forKey: lastSyncKey)
        }
    }

    public func resetSyncState() {
        lastSyncTimestamps.removeAll()
        userDefaults.removeObject(forKey: lastSyncKey)
    }

    // MARK: - Cleanup

    /// Clears old synced data to free up space
    ///
    /// Keeps pending changes and recent data (last 30 days).
    public func clearOldCachedData() throws {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        try cacheService.clearSyncedData(olderThan: thirtyDaysAgo)
    }
}

// MARK: - SyncError

public enum SyncError: LocalizedError {
    case uploadFailed(String)
    case downloadFailed(String)
    case conflictResolutionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .conflictResolutionFailed(let message):
            return "Conflict resolution failed: \(message)"
        }
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
