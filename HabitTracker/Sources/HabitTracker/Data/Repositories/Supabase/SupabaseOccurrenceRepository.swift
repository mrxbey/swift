import Foundation
import Supabase

/// Supabase implementation of OccurrenceRepository
///
/// Thread-safe actor that handles all occurrence-related database operations.
public actor SupabaseOccurrenceRepository: OccurrenceRepository {
    private let client: SupabaseClient

    // MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    // MARK: - OccurrenceRepository Implementation

    public func fetchToday() async throws -> [GoalOccurrence] {
        let today = Date()
        return try await fetchOccurrences(for: today)
    }

    public func fetchOccurrences(for date: Date) async throws -> [GoalOccurrence] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let dateString = date.toDateOnlyString()

            let response: [GoalOccurrenceDTO] = try await client
                .from("goal_occurrences")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("scheduled_date", value: dateString)
                .order("created_at", ascending: true)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchOccurrences(from: Date, to: Date) async throws -> [GoalOccurrence] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

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

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> GoalOccurrence {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: GoalOccurrenceDTO = try await client
                .from("goal_occurrences")
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return response.toDomain
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
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var occurrenceToCreate = occurrence
            if occurrenceToCreate.userId != userId {
                occurrenceToCreate = GoalOccurrence(
                    id: occurrence.id,
                    userId: userId,
                    goalId: occurrence.goalId,
                    scheduleId: occurrence.scheduleId,
                    scheduledDate: occurrence.scheduledDate,
                    targetCount: occurrence.targetCount,
                    completedCount: occurrence.completedCount,
                    status: occurrence.status,
                    renameOverride: occurrence.renameOverride,
                    contentSnapshot: occurrence.contentSnapshot,
                    lastCompletedAt: occurrence.lastCompletedAt,
                    createdAt: occurrence.createdAt,
                    updatedAt: Date()
                )
            }

            let dto = GoalOccurrenceDTO(from: occurrenceToCreate)

            let response: GoalOccurrenceDTO = try await client
                .from("goal_occurrences")
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

    public func update(_ occurrence: GoalOccurrence) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var updatedOccurrence = occurrence
            updatedOccurrence.updatedAt = Date()

            let dto = GoalOccurrenceDTO(from: updatedOccurrence)

            try await client
                .from("goal_occurrences")
                .update(dto)
                .eq("id", value: occurrence.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
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

            return response.toDomain
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }
}

// MARK: - Date Extensions

private extension Date {
    /// Converts date to ISO 8601 date-only string (yyyy-MM-dd)
    func toDateOnlyString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}
