import Foundation
import Supabase

/// Supabase implementation of AreaRepository
///
/// Thread-safe actor that handles all area-related database operations.
public actor SupabaseAreaRepository: AreaRepository {
    private let client: SupabaseClient

    // MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    /// Convenience initializer using shared service
    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    // MARK: - AreaRepository Implementation

    public func fetchAll() async throws -> [Area] {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: [AreaDTO] = try await client
                .from("areas")
                .select()
                .eq("user_id", value: userId.uuidString)
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

    public func fetch(_ id: UUID) async throws -> Area {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            let response: AreaDTO = try await client
                .from("areas")
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

    public func create(_ area: Area) async throws -> Area {
        do {
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

            let dto = AreaDTO(from: areaToCreate)

            let response: AreaDTO = try await client
                .from("areas")
                .insert(dto)
                .select()
                .single()
                .execute()
                .value

            return response.toDomain
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

    public func update(_ area: Area) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            var updatedArea = area
            updatedArea.updatedAt = Date()

            let dto = AreaDTO(from: updatedArea)

            try await client
                .from("areas")
                .update(dto)
                .eq("id", value: area.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
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

    public func delete(id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

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

    public func archive(id: UUID) async throws {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            try await client
                .from("areas")
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

    public func fetchStatistics(for id: UUID) async throws -> AreaStatistics {
        do {
            guard let userId = await client.auth.currentUser?.id else {
                throw SupabaseError.unauthorized
            }

            // Use RPC to fetch statistics
            struct StatsRow: Codable {
                let activeGoalsCount: Int
                let completedGoalsCount: Int
                let totalPoints: Int
                let completionRate: Double
                let currentStreak: Int

                enum CodingKeys: String, CodingKey {
                    case activeGoalsCount = "active_goals_count"
                    case completedGoalsCount = "completed_goals_count"
                    case totalPoints = "total_points"
                    case completionRate = "completion_rate"
                    case currentStreak = "current_streak"
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
                activeGoalsCount: response.activeGoalsCount,
                completedGoalsCount: response.completedGoalsCount,
                totalPoints: response.totalPoints,
                completionRate: response.completionRate,
                currentStreak: response.currentStreak
            )
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
