import Foundation

/// Repository protocol for managing Goal entities
///
/// Provides CRUD operations and queries for goals across different contexts.
public protocol GoalRepository: Sendable {
    /// Fetches all active goals for the current user
    ///
    /// - Returns: Array of goals sorted by creation date
    /// - Throws: SupabaseError if the operation fails
    func fetchAll() async throws -> [Goal]

    /// Fetches goals for a specific area
    ///
    /// - Parameter areaId: The UUID of the area
    /// - Returns: Array of goals in that area
    /// - Throws: SupabaseError if the operation fails
    func fetchGoals(for areaId: UUID) async throws -> [Goal]

    /// Fetches a specific goal by ID
    ///
    /// - Parameter id: The UUID of the goal to fetch
    /// - Returns: The goal if found
    /// - Throws: SupabaseError.notFound if goal doesn't exist
    func fetch(_ id: UUID) async throws -> Goal

    /// Creates a new goal
    ///
    /// - Parameter goal: The goal to create
    /// - Returns: The created goal with server-generated fields
    /// - Throws: SupabaseError if the operation fails
    func create(_ goal: Goal) async throws -> Goal

    /// Updates an existing goal
    ///
    /// - Parameter goal: The goal to update
    /// - Throws: SupabaseError if the operation fails
    func update(_ goal: Goal) async throws

    /// Deletes a goal by ID
    ///
    /// - Parameter id: The UUID of the goal to delete
    /// - Throws: SupabaseError if the operation fails
    func delete(id: UUID) async throws

    /// Archives a goal (soft delete)
    ///
    /// - Parameter id: The UUID of the goal to archive
    /// - Throws: SupabaseError if the operation fails
    func archive(id: UUID) async throws

    /// Completes a goal (marks as done)
    ///
    /// - Parameter id: The UUID of the goal to complete
    /// - Throws: SupabaseError if the operation fails
    func complete(id: UUID) async throws

    /// Searches goals by hashtag
    ///
    /// - Parameter hashtag: The hashtag to search for (without #)
    /// - Returns: Array of goals containing that hashtag
    /// - Throws: SupabaseError if the operation fails
    func searchByHashtag(_ hashtag: String) async throws -> [Goal]

    /// Fetches the most completed goals
    ///
    /// - Parameters:
    ///   - limit: Maximum number of goals to return
    ///   - days: Number of days to look back
    /// - Returns: Array of goals sorted by completion count
    /// - Throws: SupabaseError if the operation fails
    func fetchMostCompleted(limit: Int, days: Int) async throws -> [GoalWithStats]
}

/// MARK: - GoalWithStats

/// A goal with completion statistics
public struct GoalWithStats: Codable, Sendable, Equatable {
    public let goal: Goal
    public let completionCount: Int
    public let targetCount: Int
    public let completionRate: Double
    public let totalPoints: Int

    public init(
        goal: Goal,
        completionCount: Int,
        targetCount: Int,
        completionRate: Double,
        totalPoints: Int
    ) {
        self.goal = goal
        self.completionCount = completionCount
        self.targetCount = targetCount
        self.completionRate = completionRate
        self.totalPoints = totalPoints
    }
}
