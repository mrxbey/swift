import Foundation
import Supabase

/// Supabase implementation of GoalRepository
///
/// Thread-safe actor that handles all goal-related database operations.
public actor SupabaseGoalRepository: GoalRepository {
    private let client: SupabaseClient

    // MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    // MARK: - GoalRepository Implementation

    public func fetchAll() async throws -> [Goal] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: [GoalDTO] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchGoals(for areaId: UUID) async throws -> [Goal] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: [GoalDTO] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("area_id", value: areaId.uuidString)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Goal {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: GoalDTO = try await client
                .from("goals")
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

    public func create(_ goal: Goal) async throws -> Goal {
        do {
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

            let dto = GoalDTO(from: goalToCreate)

            let response: GoalDTO = try await client
                .from("goals")
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

    public func update(_ goal: Goal) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var updatedGoal = goal
            updatedGoal.updatedAt = Date()

            let dto = GoalDTO(from: updatedGoal)

            try await client
                .from("goals")
                .update(dto)
                .eq("id", value: goal.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func delete(id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

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

    public func archive(id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            try await client
                .from("goals")
                .update(["status": "archived", "updated_at": Date().iso8601String])
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func complete(id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            try await client
                .from("goals")
                .update(["status": "completed", "updated_at": Date().iso8601String])
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
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

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
