import Foundation

/// Repository protocol for managing Area entities
///
/// Provides an abstraction layer between the domain logic and data source.
/// Implementations can use Supabase, local cache, or mock data.
public protocol AreaRepository: Sendable {
    /// Fetches all areas for the current user
    ///
    /// - Returns: Array of areas sorted by creation date
    /// - Throws: SupabaseError if the operation fails
    func fetchAll() async throws -> [Area]

    /// Fetches a specific area by ID
    ///
    /// - Parameter id: The UUID of the area to fetch
    /// - Returns: The area if found
    /// - Throws: SupabaseError.notFound if area doesn't exist
    func fetch(_ id: UUID) async throws -> Area

    /// Creates a new area
    ///
    /// - Parameter area: The area to create
    /// - Returns: The created area with server-generated fields
    /// - Throws: SupabaseError.duplicateEntry if name already exists
    func create(_ area: Area) async throws -> Area

    /// Updates an existing area
    ///
    /// - Parameter area: The area to update
    /// - Throws: SupabaseError if the operation fails
    func update(_ area: Area) async throws

    /// Deletes an area by ID
    ///
    /// - Parameter id: The UUID of the area to delete
    /// - Throws: SupabaseError if the operation fails
    func delete(id: UUID) async throws

    /// Archives an area (soft delete)
    ///
    /// - Parameter id: The UUID of the area to archive
    /// - Throws: SupabaseError if the operation fails
    func archive(id: UUID) async throws

    /// Fetches statistics for an area
    ///
    /// - Parameter id: The UUID of the area
    /// - Returns: Statistics including goal count, completion rate, etc.
    /// - Throws: SupabaseError if the operation fails
    func fetchStatistics(for id: UUID) async throws -> AreaStatistics
}

// MARK: - AreaStatistics

/// Statistics for an area
public struct AreaStatistics: Codable, Sendable, Equatable {
    public let areaId: UUID
    public let activeGoalsCount: Int
    public let completedGoalsCount: Int
    public let totalPoints: Int
    public let completionRate: Double
    public let currentStreak: Int

    public init(
        areaId: UUID,
        activeGoalsCount: Int,
        completedGoalsCount: Int,
        totalPoints: Int,
        completionRate: Double,
        currentStreak: Int
    ) {
        self.areaId = areaId
        self.activeGoalsCount = activeGoalsCount
        self.completedGoalsCount = completedGoalsCount
        self.totalPoints = totalPoints
        self.completionRate = completionRate
        self.currentStreak = currentStreak
    }
}
