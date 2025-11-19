import Foundation
import Supabase

/// Supabase implementation of OccurrenceRepository with offline-first caching
///
/// Thread-safe actor that handles all occurrence-related database operations.
/// Implements cache-first reads and write-through pattern for offline support.
public actor SupabaseOccurrenceRepository: OccurrenceRepository {
    private let client: SupabaseClient
    private let cacheService: CacheService
    private let networkMonitor: NetworkMonitor
    private let syncEngine: SyncEngine

    /// MARK: - Initialization

    public init(
        client: SupabaseClient,
        cacheService: CacheService,
        networkMonitor: NetworkMonitor,
        syncEngine: SyncEngine
    ) {
        self.client = client
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
        self.syncEngine = syncEngine
    }

    /// Convenience initializer using shared service and dependencies
    ///
    /// - Throws: CacheService initialization errors (disk full, permissions, etc.)
    public init() async throws {
        self.client = await SupabaseService.shared.getClient()
        let sharedCache = try CacheService()
        self.cacheService = sharedCache
        self.networkMonitor = NetworkMonitor()
        self.syncEngine = SyncEngine(
            cacheService: sharedCache,
            supabaseClient: await SupabaseService.shared.getClient()
        )
    }

    /// MARK: - OccurrenceRepository Implementation

    public func fetchToday() async throws -> [GoalOccurrence] {
        let today = Date()
        return try await fetchOccurrences(for: today)
    }

    public func fetchOccurrences(for date: Date) async throws -> [GoalOccurrence] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try cacheService.fetchOccurrences(userId: userId, date: date)

        if !cached.isEmpty {
            // If online, sync first to ensure fresh data
            if await networkMonitor.isConnected() {
                do {
                    try await syncEngine.performFullSync(userId: userId)
                } catch {
                    // Log sync error but continue with cached data
                    print("⚠️ [SupabaseOccurrenceRepository] Sync failed in fetchOccurrences: \(error.localizedDescription)")
                }
                // Return fresh data from cache after sync (or cached data if sync failed)
                return try cacheService.fetchOccurrences(userId: userId, date: date)
            }
            // Offline: return cached data
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let dateString = date.toDateOnlyString()

            let response: [GoalOccurrenceDTO] = try await client
                .from("goal_occurrences")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("scheduled_date", value: dateString)
                .order("created_at", ascending: true)
                .execute()
                .value

            let occurrences = response.map(\.toDomain)

            // Cache the results
            for occurrence in occurrences {
                try cacheService.saveOccurrence(occurrence, syncState: .synced)
            }

            return occurrences
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchOccurrences(from: Date, to: Date) async throws -> [GoalOccurrence] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // For range queries, always fetch from Supabase and refresh cache
        // This is because the cache doesn't have an efficient range query yet
        do {
            let fromString = from.toDateOnlyString()
            let toString = to.toDateOnlyString()

            let response: [GoalOccurrenceDTO] = try await client
                .from("goal_occurrences")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("scheduled_date", value: fromString)
                .lte("scheduled_date", value: toString)
                .order("scheduled_date", ascending: true)
                .execute()
                .value

            let occurrences = response.map(\.toDomain)

            // Cache the results
            for occurrence in occurrences {
                try cacheService.saveOccurrence(occurrence, syncState: .synced)
            }

            return occurrences
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> GoalOccurrence {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        if let cached = try cacheService.fetchOccurrence(id: id) {
            // Trigger background sync
            Task {
                if await networkMonitor.isConnected() {
                    do {
                        try await syncEngine.performFullSync(userId: userId)
                    } catch {
                        print("⚠️ [SupabaseOccurrenceRepository] Background sync failed in fetch: \(error.localizedDescription)")
                    }
                }
            }
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: GoalOccurrenceDTO = try await client
                .from("goal_occurrences")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let occurrence = response.toDomain

            // Cache the result
                            try cacheService.saveOccurrence(occurrence, syncState: .synced)

            return occurrence
        } catch let error as PostgrestError {
            if error.statusCode == 404 {
                throw SupabaseError.notFound
            }
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ occurrence: GoalOccurrence) async throws -> GoalOccurrence {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var occurrenceToCreate = occurrence
        if occurrenceToCreate.userId != userId {
            occurrenceToCreate = GoalOccurrence(
                id: occurrence.id,
                goalId: occurrence.goalId,
                userId: userId,
                scheduledDate: occurrence.scheduledDate,
                dueAt: occurrence.dueAt,
                status: occurrence.status,
                targetCount: occurrence.targetCount,
                completedCount: occurrence.completedCount,
                keepUntilComplete: occurrence.keepUntilComplete,
                rolledFromId: occurrence.rolledFromId,
                rolledIntoId: occurrence.rolledIntoId,
                nameOverride: occurrence.nameOverride,
                emojiOverride: occurrence.emojiOverride,
                contentSnapshot: occurrence.contentSnapshot,
                isOneTime: occurrence.isOneTime,
                createdAt: occurrence.createdAt,
                updatedAt: Date()
            )
        }

        // Save to cache with pending state
                    try cacheService.saveOccurrence(occurrenceToCreate, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = GoalOccurrenceDTO(from: occurrenceToCreate)

                let response: GoalOccurrenceDTO = try await client
                    .from("goal_occurrences")
                    .insert(dto)
                    .select()
                    .single()
                    .execute()
                    .value

                let created = response.toDomain

                // Update cache with synced state
                                    try cacheService.saveOccurrence(created, syncState: .synced)

                return created
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }

        // Offline: Return cached version
        return occurrenceToCreate
    }

    public func update(_ occurrence: GoalOccurrence) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var updatedOccurrence = occurrence
        updatedOccurrence.updatedAt = Date()

        // Save to cache with pending state
                    try cacheService.saveOccurrence(updatedOccurrence, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = GoalOccurrenceDTO(from: updatedOccurrence)

                try await client
                    .from("goal_occurrences")
                    .update(dto)
                    .eq("id", value: occurrence.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                                    try cacheService.saveOccurrence(updatedOccurrence, syncState: .synced)
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state
    }

    public func completeTick(_ id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            // Use RPC for atomic operation with points tracking
            try await client
                .rpc("complete_tick", params: [
                    "p_occ": id.uuidString,
                    "p_user": userId.uuidString
                ])
                .execute()

            // Update cache with latest state
            do {
                let updated = try await fetchOccurrenceFromSupabase(id, userId: userId)
                try cacheService.saveOccurrence(updated, syncState: .synced)
            } catch {
                print("⚠️ [SupabaseOccurrenceRepository] Failed to refresh cache after RPC: \(error.localizedDescription)")
                // Cache will be updated on next sync
            }
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func skip(_ id: UUID, reason: String?) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var params: [String: Any] = [
                "p_occ": id.uuidString,
                "p_user": userId.uuidString
            ]

            if let reason = reason {
                params["p_reason"] = reason
            }

            // Use RPC for proper event logging
            try await client
                .rpc("skip_occurrence", params: params)
                .execute()

            // Update cache with latest state
            do {
                let updated = try await fetchOccurrenceFromSupabase(id, userId: userId)
                try cacheService.saveOccurrence(updated, syncState: .synced)
            } catch {
                print("⚠️ [SupabaseOccurrenceRepository] Failed to refresh cache after RPC: \(error.localizedDescription)")
                // Cache will be updated on next sync
            }
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func rename(_ id: UUID, to newName: String) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            // Use RPC for rename operation
            try await client
                .rpc("rename_occurrence", params: [
                    "p_occ": id.uuidString,
                    "p_name": newName,
                    "p_user": userId.uuidString
                ])
                .execute()

            // Update cache with latest state
            do {
                let updated = try await fetchOccurrenceFromSupabase(id, userId: userId)
                try cacheService.saveOccurrence(updated, syncState: .synced)
            } catch {
                print("⚠️ [SupabaseOccurrenceRepository] Failed to refresh cache after RPC: \(error.localizedDescription)")
                // Cache will be updated on next sync
            }
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func ensureOccurrence(for goalId: UUID, on date: Date) async throws -> GoalOccurrence {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let dateString = date.toDateOnlyString()

            // Use RPC to ensure occurrence exists
            let response: GoalOccurrenceDTO = try await client
                .rpc("ensure_occurrence", params: [
                    "p_goal": goalId.uuidString,
                    "p_date": dateString,
                    "p_user": userId.uuidString
                ])
                .single()
                .execute()
                .value

            let occurrence = response.toDomain

            // Update cache
                            try cacheService.saveOccurrence(occurrence, syncState: .synced)

            return occurrence
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    /// MARK: - Private Helpers

    /// Fetches an occurrence from Supabase by ID
    ///
    /// Used to refresh cache after RPC operations that modify data
    private func fetchOccurrenceFromSupabase(_ id: UUID, userId: UUID) async throws -> GoalOccurrence {
        let response: GoalOccurrenceDTO = try await client
            .from("goal_occurrences")
            .select()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return response.toDomain
    }
}

/// MARK: - Date Extensions

private extension Date {
    /// Converts date to ISO 8601 date-only string (yyyy-MM-dd)
    func toDateOnlyString() -> String {
        return Self.dateOnlyFormatter.string(from: self)
    }

    // Cached formatter to avoid creating new instance on every call
    private static let dateOnlyFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
