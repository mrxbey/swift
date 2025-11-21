import Foundation
import Supabase

/// Supabase implementation of AreaRepository with offline-first caching
///
/// Thread-safe actor that handles all area-related database operations.
/// Implements cache-first reads and write-through pattern for offline support.
public actor SupabaseAreaRepository: AreaRepository {
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

    /// MARK: - AreaRepository Implementation

    public func fetchAll() async throws -> [Area] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        let cached = try cacheService.fetchAreas(userId: userId)

        if !cached.isEmpty {
            // If online, sync first to ensure fresh data
            if await networkMonitor.isConnected() {
                try? await syncEngine.performFullSync(userId: userId)
                // Return fresh data from cache after sync
                return try cacheService.fetchAreas(userId: userId)
            }
            // Offline: return cached data
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: [AreaDTO] = try await client
                .from("areas")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            let areas = response.map(\.toDomain)

            // Cache the results
            for area in areas {
                try cacheService.saveArea(area, syncState: .synced)
            }

            return areas
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Area {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Cache-first: Try to get from cache
        if let cached = try cacheService.fetchArea(id: id) {
            // Trigger background sync to refresh
            Task {
                if await networkMonitor.isConnected() {
                    try? await syncEngine.performFullSync(userId: userId)
                }
            }
            return cached
        }

        // Cache miss: Fetch from Supabase
        do {
            let response: AreaDTO = try await client
                .from("areas")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            let area = response.toDomain

            // Cache the result
            try cacheService.saveArea(area, syncState: .synced)

            return area
        } catch let error as PostgrestError {
            if error.statusCode == 404 {
                throw SupabaseError.notFound
            }
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ area: Area) async throws -> Area {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Ensure user_id matches authenticated user
        var areaToCreate = area
        if areaToCreate.userId != userId {
            areaToCreate = Area(
                id: area.id,
                userId: userId,
                name: area.name,
                emoji: area.emoji,
                colorHex: area.colorHex,
                status: area.status,
                createdAt: area.createdAt,
                updatedAt: Date()
            )
        }

        // Save to cache first with pending state
        try cacheService.saveArea(areaToCreate, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = AreaDTO(from: areaToCreate)

                let response: AreaDTO = try await client
                    .from("areas")
                    .insert(dto)
                    .select()
                    .single()
                    .execute()
                    .value

                let created = response.toDomain

                // Update cache with synced state
                try cacheService.saveArea(created, syncState: .synced)

                return created
            } catch let error as PostgrestError {
                // Check for unique constraint violation
                if let message = error.message,
                   message.contains("duplicate") || message.contains("unique") {
                    throw SupabaseError.duplicateEntry("area name")
                }
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }

        // Offline: Return cached version (will sync later)
        return areaToCreate
    }

    public func update(_ area: Area) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var updatedArea = area
        updatedArea.updatedAt = Date()

        // Save to cache first with pending state
        try cacheService.saveArea(updatedArea, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                let dto = AreaDTO(from: updatedArea)

                try await client
                    .from("areas")
                    .update(dto)
                    .eq("id", value: area.id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                try cacheService.saveArea(updatedArea, syncState: .synced)
            } catch let error as PostgrestError {
                if let message = error.message,
                   message.contains("duplicate") || message.contains("unique") {
                    throw SupabaseError.duplicateEntry("area name")
                }
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state (will sync later)
    }

    public func delete(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Delete from cache
        try cacheService.deleteArea(id: id)

        // Try to sync deletion to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                try await client
                    .from("areas")
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
        // Offline: Deletion will be synced later via pending changes
    }

    public func archive(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Fetch area from cache, update status, and save
        guard let area = try cacheService.fetchArea(id: id) else {
            throw SupabaseError.notFound
        }

        var archivedArea = area
        archivedArea.status = .archived
        archivedArea.updatedAt = Date()

        // Save to cache with pending state
        try cacheService.saveArea(archivedArea, syncState: .pending)

        // Try to sync to Supabase if online
        if await networkMonitor.isConnected() {
            do {
                try await client
                    .from("areas")
                    .update(["status": "archived", "updated_at": Date().iso8601String])
                    .eq("id", value: id.uuidString)
                    .eq("user_id", value: userId.uuidString)
                    .execute()

                // Update cache with synced state
                try cacheService.saveArea(archivedArea, syncState: .synced)
            } catch let error as PostgrestError {
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }
        // Offline: Keep pending state (will sync later)
    }

    public func fetchStatistics(for id: UUID) async throws -> AreaStatistics {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            // Use RPC to fetch statistics
            struct StatsRow: Codable {
                let totalGoals: Int
                let activeGoals: Int
                let totalCompletions: Int
                let completionRate: Double

                enum CodingKeys: String, CodingKey {
                    case totalGoals = "total_goals"
                    case activeGoals = "active_goals"
                    case totalCompletions = "total_completions"
                    case completionRate = "completion_rate"
                }
            }

            let response: StatsRow = try await client
                .rpc("get_area_statistics", params: [
                    "p_area": id.uuidString,
                    "p_user": userId.uuidString
                ])
                .single()
                .execute()
                .value

            return AreaStatistics(
                areaId: id,
                totalGoals: response.totalGoals,
                activeGoals: response.activeGoals,
                totalCompletions: response.totalCompletions,
                completionRate: response.completionRate
            )
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
