import Foundation
import Supabase

/// Supabase implementation of GoalRepository with offline-first caching
///
/// Thread-safe actor that handles all goal-related database operations.
/// Implements cache-first reads and write-through pattern for offline support.
public actor SupabaseGoalRepository: GoalRepository {
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
        self.client = try await SupabaseService.shared.getClient()
        let sharedCache = try CacheService()
        self.cacheService = sharedCache
        self.networkMonitor = NetworkMonitor()
        self.syncEngine = SyncEngine(
            cacheService: sharedCache,
            supabaseClient: try await SupabaseService.shared.getClient()
        )
    }

    /// MARK: - GoalRepository Implementation

    public func fetchAll() async throws -> [Goal] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try cacheService.fetchGoals(userId: userId).filter { $0.status == .active }

        if !cached.isEmpty {
            // If online, sync first to ensure fresh data
            if await networkMonitor.isConnected() {
                try? await syncEngine.performFullSync(userId: userId)
                // Return fresh data from cache after sync
                return                     try cacheService.fetchGoals(userId: userId).filter { $0.status == .active }
            }
            // Offline: return cached data
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: [GoalDTO] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
                .value

            let goals = response.map(\.toDomain)

            // Cache the results
            for goal in goals {
                try cacheService.saveGoal(goal, syncState: .synced)
            }

            return goals
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchGoals(for areaId: UUID) async throws -> [Goal] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try cacheService.fetchGoals(areaId: areaId).filter { $0.status == .active }

        if !cached.isEmpty {
            // If online, sync first to ensure fresh data
            if await networkMonitor.isConnected() {
                try? await syncEngine.performFullSync(userId: userId)
                // Return fresh data from cache after sync
                return                     try cacheService.fetchGoals(areaId: areaId).filter { $0.status == .active }
            }
            // Offline: return cached data
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: [GoalDTO] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("area_id", value: areaId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
                .value

            let goals = response.map(\.toDomain)

            // Cache the results
            for goal in goals {
                try cacheService.saveGoal(goal, syncState: .synced)
            }

            return goals
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Goal {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        if let cached = try cacheService.fetchGoal(id: id) {
            // Trigger background sync
            Task {
                if await networkMonitor.isConnected() {
                    try? await syncEngine.performFullSync(userId: userId)
                }
            }
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: GoalDTO = try await client
                .from("goals")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let goal = response.toDomain

            // Cache the result
                            try cacheService.saveGoal(goal, syncState: .synced)

            return goal
        } catch let error as PostgrestError {
            if error.statusCode == 404 {
                throw SupabaseError.notFound
            }
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ goal: Goal) async throws -> Goal {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var goalToCreate = goal
        if goalToCreate.userId != userId {
            goalToCreate = Goal(
                id: goal.id,
                userId: userId,
                areaId: goal.areaId,
                title: goal.title,
                emoji: goal.emoji,
                kind: goal.kind,
                status: goal.status,
                keepUntilComplete: goal.keepUntilComplete,
                timesPerDay: goal.timesPerDay,
                pointsPerCompletion: goal.pointsPerCompletion,
                linkedExerciseKey: goal.linkedExerciseKey,
                hashtags: goal.hashtags,
                createdAt: goal.createdAt,
                updatedAt: Date()
            )
        }

        // Save to cache first with pending state
                    try cacheService.saveGoal(goalToCreate, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = GoalDTO(from: goalToCreate)

                let response: GoalDTO = try await client
                    .from("goals")
                    .insert(dto)
                    .select()
                    .single()
                    .execute()
                    .value

                let created = response.toDomain

                // Update cache with synced state
                                    try cacheService.saveGoal(created, syncState: .synced)

                return created
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }

        // Offline: Return cached version
        return goalToCreate
    }

    public func update(_ goal: Goal) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var updatedGoal = goal
        updatedGoal.updatedAt = Date()

        // Save to cache with pending state
                    try cacheService.saveGoal(updatedGoal, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = GoalDTO(from: updatedGoal)

                try await client
                    .from("goals")
                    .update(dto)
                    .eq("id", value: goal.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                                    try cacheService.saveGoal(updatedGoal, syncState: .synced)
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state
    }

    public func delete(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Delete from cache
                    try cacheService.deleteGoal(id: id)

        // Try to sync deletion to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                try await client
                    .from("goals")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Deletion will be synced later
    }

    public func archive(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Fetch goal from cache, update status, and save
        guard let goal = try cacheService.fetchGoal(id: id) else {
            throw SupabaseError.notFound
        }

        var archivedGoal = goal
        archivedGoal.status = .archived
        archivedGoal.updatedAt = Date()

        // Save to cache with pending state
                    try cacheService.saveGoal(archivedGoal, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                try await client
                    .from("goals")
                    .update(["status": "archived", "updated_at": Date().iso8601String])
                    .eq("id", value: id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                                    try cacheService.saveGoal(archivedGoal, syncState: .synced)
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state
    }

    public func searchByHashtag(_ hashtag: String) async throws -> [Goal] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: [GoalDTO] = try await client
                .rpc("search_by_hashtag", params: [
                    "p_hashtag": hashtag,
                    "p_user": userId.uuidString
                ])
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchMostCompleted(limit: Int, days: Int) async throws -> [GoalWithStats] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            struct StatsRow: Codable {
                let goal: GoalDTO
                let completionCount: Int
                let targetCount: Int
                let completionRate: Double
                let totalPoints: Int

                enum CodingKeys: String, CodingKey {
                    case goal
                    case completionCount = "completion_count"
                    case targetCount = "target_count"
                    case completionRate = "completion_rate"
                    case totalPoints = "total_points"
                }
            }

            let response: [StatsRow] = try await client
                .rpc("get_most_completed_goals", params: [
                    "p_user": userId.uuidString,
                    "p_limit": limit,
                    "p_days": days
                ])
                .execute()
                .value

            return response.map { row in
                GoalWithStats(
                    goal: row.goal.toDomain,
                    completionCount: row.completionCount,
                    targetCount: row.targetCount,
                    completionRate: row.completionRate,
                    totalPoints: row.totalPoints
                )
            }
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
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
