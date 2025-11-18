import Foundation
import Supabase

/// Service for calling Supabase Remote Procedure Calls (RPCs)
///
/// Provides a centralized interface for all database RPCs defined in migration 003.
/// All RPC methods are thread-safe and handle authentication automatically.
public actor RPCService {
    private let client: SupabaseClient

    // MARK: - Initialization

    public init(client: SupabaseClient) {
        self.client = client
    }

    public init() {
        self.client = SupabaseService.shared.getClient()
    }

    // MARK: - Occurrence RPCs

    /// Completes a tick for an occurrence
    ///
    /// Increments the completed_count and updates status if target reached.
    /// Awards points and logs the event.
    ///
    /// - Parameter occurrenceId: The UUID of the occurrence
    /// - Throws: SupabaseError if the operation fails
    public func completeTick(_ occurrenceId: UUID) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        try await client
            .rpc("complete_tick", params: [
                "p_occ": occurrenceId.uuidString,
                "p_user": userId.uuidString
            ])
            .execute()
    }

    /// Skips an occurrence
    ///
    /// Marks the occurrence as skipped and logs the reason.
    ///
    /// - Parameters:
    ///   - occurrenceId: The UUID of the occurrence
    ///   - reason: Optional reason for skipping
    /// - Throws: SupabaseError if the operation fails
    public func skipOccurrence(_ occurrenceId: UUID, reason: String? = nil) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var params: [String: Any] = [
            "p_occ": occurrenceId.uuidString,
            "p_user": userId.uuidString
        ]

        if let reason = reason {
            params["p_reason"] = reason
        }

        try await client
            .rpc("skip_occurrence", params: params)
            .execute()
    }

    /// Renames an occurrence
    ///
    /// Sets a custom name override for this specific occurrence.
    ///
    /// - Parameters:
    ///   - occurrenceId: The UUID of the occurrence
    ///   - newName: The new name
    /// - Throws: SupabaseError if the operation fails
    public func renameOccurrence(_ occurrenceId: UUID, to newName: String) async throws {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        try await client
            .rpc("rename_occurrence", params: [
                "p_occ": occurrenceId.uuidString,
                "p_name": newName,
                "p_user": userId.uuidString
            ])
            .execute()
    }

    /// Ensures an occurrence exists for a goal on a date
    ///
    /// Creates the occurrence if it doesn't exist, or returns existing one.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - date: The date for the occurrence
    /// - Returns: The occurrence
    /// - Throws: SupabaseError if the operation fails
    public func ensureOccurrence(for goalId: UUID, on date: Date) async throws -> GoalOccurrence {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        let dateString = date.toDateOnlyString()

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
    }

    // MARK: - Measurement RPCs

    /// Sets or updates a measure target for a goal
    ///
    /// Creates a new versioned target, closing any previous target.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - targetValue: The target value
    ///   - unit: The unit of measurement
    ///   - effectiveFrom: When this target becomes effective
    /// - Returns: The measure target
    /// - Throws: SupabaseError if the operation fails
    public func setMeasureTarget(
        for goalId: UUID,
        targetValue: Double,
        unit: UnitKind,
        effectiveFrom: Date
    ) async throws -> GoalMeasureTarget {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        let response: GoalMeasureTargetDTO = try await client
            .rpc("set_measure_target", params: [
                "p_goal": goalId.uuidString,
                "p_target": targetValue,
                "p_unit": unit.rawValue,
                "p_from": effectiveFrom.toDateOnlyString(),
                "p_user": userId.uuidString
            ])
            .single()
            .execute()
            .value

        return response.toDomain
    }

    /// Adds a measurement to a goal
    ///
    /// Records the measurement and updates related occurrence if provided.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - value: The measurement value
    ///   - unit: The unit of measurement
    ///   - occurrenceId: Optional occurrence to link to
    /// - Returns: The created measurement
    /// - Throws: SupabaseError if the operation fails
    public func addMeasurement(
        for goalId: UUID,
        value: Double,
        unit: UnitKind,
        occurrenceId: UUID? = nil
    ) async throws -> Measurement {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        var params: [String: Any] = [
            "p_goal": goalId.uuidString,
            "p_value": value,
            "p_unit": unit.rawValue,
            "p_user": userId.uuidString
        ]

        if let occurrenceId = occurrenceId {
            params["p_occ"] = occurrenceId.uuidString
        }

        let response: MeasurementDTO = try await client
            .rpc("add_measurement", params: params)
            .single()
            .execute()
            .value

        return response.toDomain
    }

    /// Fetches water progress data for charting
    ///
    /// Returns daily consumption vs target for the date range.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the water goal
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Array of daily water data points
    /// - Throws: SupabaseError if the operation fails
    public func getWaterProgress(
        for goalId: UUID,
        from: Date,
        to: Date
    ) async throws -> [WaterDataPoint] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        struct WaterRow: Codable {
            let day: String
            let consumed: Double
            let target: Double
            let unit: String
        }

        let response: [WaterRow] = try await client
            .rpc("get_water_progress", params: [
                "p_goal": goalId.uuidString,
                "p_from": from.toDateOnlyString(),
                "p_to": to.toDateOnlyString(),
                "p_user": userId.uuidString
            ])
            .execute()
            .value

        return response.compactMap { row in
            guard let date = row.day.toDate() else { return nil }
            return WaterDataPoint(
                date: date,
                consumed: row.consumed,
                target: row.target,
                unit: UnitKind(rawValue: row.unit) ?? .ml
            )
        }
    }

    // MARK: - Analytics RPCs

    /// Gets the current streak for the user
    ///
    /// Returns consecutive days with at least one completion.
    ///
    /// - Returns: Number of consecutive days
    /// - Throws: SupabaseError if the operation fails
    public func getCurrentStreak() async throws -> Int {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        let response: Int = try await client
            .rpc("get_current_streak", params: [
                "p_user": userId.uuidString
            ])
            .single()
            .execute()
            .value

        return response
    }

    /// Gets the longest streak for the user
    ///
    /// Returns the maximum consecutive days with at least one completion.
    ///
    /// - Returns: Number of consecutive days
    /// - Throws: SupabaseError if the operation fails
    public func getLongestStreak() async throws -> Int {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        let response: Int = try await client
            .rpc("get_longest_streak", params: [
                "p_user": userId.uuidString
            ])
            .single()
            .execute()
            .value

        return response
    }

    /// Gets the most completed goals
    ///
    /// Returns goals sorted by completion count within the specified timeframe.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of goals to return
    ///   - days: Number of days to look back
    /// - Returns: Array of goals with statistics
    /// - Throws: SupabaseError if the operation fails
    public func getMostCompletedGoals(limit: Int = 10, days: Int = 30) async throws -> [GoalWithStats] {
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
    }

    /// Gets statistics for an area
    ///
    /// Returns aggregated statistics for all goals in the area.
    ///
    /// - Parameter areaId: The UUID of the area
    /// - Returns: Area statistics
    /// - Throws: SupabaseError if the operation fails
    public func getAreaStatistics(for areaId: UUID) async throws -> AreaStatistics {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

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
                "p_area": areaId.uuidString,
                "p_user": userId.uuidString
            ])
            .single()
            .execute()
            .value

        return AreaStatistics(
            areaId: areaId,
            activeGoalsCount: response.activeGoalsCount,
            completedGoalsCount: response.completedGoalsCount,
            totalPoints: response.totalPoints,
            completionRate: response.completionRate,
            currentStreak: response.currentStreak
        )
    }

    /// Searches goals by hashtag
    ///
    /// Returns all goals containing the specified hashtag.
    ///
    /// - Parameter hashtag: The hashtag to search for (without #)
    /// - Returns: Array of matching goals
    /// - Throws: SupabaseError if the operation fails
    public func searchByHashtag(_ hashtag: String) async throws -> [Goal] {
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
    }
}

// MARK: - Date Extensions

private extension Date {
    func toDateOnlyString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}

private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: self)
    }
}
