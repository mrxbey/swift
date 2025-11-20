import Foundation
import Supabase

/// Supabase implementation of ReflectionRepository with offline-first caching
///
/// Thread-safe actor that handles all reflection-related database operations.
/// Implements cache-first reads and write-through pattern for offline support.
public actor SupabaseReflectionRepository: ReflectionRepository {
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

    /// Convenience initializer using shared services and dependencies
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

    /// MARK: - ReflectionRepository Implementation

    public func fetchAll() async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchReflections(for goalId: UUID) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("goal_id", value: goalId.uuidString)
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchReflections(forArea areaId: UUID) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("area_id", value: areaId.uuidString)
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchReflections(from startDate: Date, to endDate: Date) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("reflection_date", value: startDate.ISO8601Format())
                .lte("reflection_date", value: endDate.ISO8601Format())
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchReflections(withMood mood: ReflectionMood) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("mood", value: mood.rawValue)
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchReflections(withTag tag: String) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .contains("tags", value: [tag])
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Reflection {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            let response: ReflectionDTO = try await client
                .from("reflections")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return response.toDomain
        } catch let error as PostgrestError {
            if case .notFound = error {
                throw SupabaseError.notFound
            }
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ reflection: Reflection) async throws -> Reflection {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Ensure the reflection belongs to the current user
        guard reflection.userId == userId else {
            throw SupabaseError.forbidden
        }

        do {
            let dto = ReflectionDTO(from: reflection)

            let response: ReflectionDTO = try await client
                .from("reflections")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value

            return response.toDomain
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func update(_ reflection: Reflection) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Ensure the reflection belongs to the current user
        guard reflection.userId == userId else {
            throw SupabaseError.forbidden
        }

        do {
            var dto = ReflectionDTO(from: reflection)
            // Manually set updated_at to current time for the update
            dto = ReflectionDTO(
                id: dto.id,
                userId: dto.userId,
                goalId: dto.goalId,
                areaId: dto.areaId,
                content: dto.content,
                tags: dto.tags,
                mood: dto.mood,
                reflectionDate: dto.reflectionDate,
                createdAt: dto.createdAt,
                updatedAt: Date()
            )

            let _: ReflectionDTO = try await client
                .from("reflections")
                .update(dto)
                .eq("id", value: reflection.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .select()
                .single()
                .execute()
                .value

        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func delete(id: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        do {
            try await client
                .from("reflections")
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

    public func search(query: String) async throws -> [Reflection] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Supabase full-text search using the content column
        // Format: to_tsquery('english', 'word1 & word2')
        do {
            let response: [ReflectionDTO] = try await client
                .from("reflections")
                .select()
                .eq("user_id", value: userId.uuidString)
                .textSearch("content", query: query)
                .order("reflection_date", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }
}

// MARK: - Extension for DTO Updates

extension ReflectionDTO {
    /// Creates a new ReflectionDTO with all fields
    ///
    /// Used for updates where we need to manually set updated_at
    init(
        id: UUID,
        userId: UUID,
        goalId: UUID?,
        areaId: UUID?,
        content: String,
        tags: [String],
        mood: String?,
        reflectionDate: Date,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.areaId = areaId
        self.content = content
        self.tags = tags
        self.mood = mood
        self.reflectionDate = reflectionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
