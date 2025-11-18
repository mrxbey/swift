import Foundation

/// Repository protocol for managing GoalOccurrence entities
///
/// Handles daily instances of scheduled goals with completion tracking.
public protocol OccurrenceRepository: Sendable {
    /// Fetches today's occurrences for the current user
    ///
    /// - Returns: Array of occurrences scheduled for today
    /// - Throws: SupabaseError if the operation fails
    func fetchToday() async throws -> [GoalOccurrence]

    /// Fetches occurrences for a specific date
    ///
    /// - Parameter date: The date to fetch occurrences for
    /// - Returns: Array of occurrences scheduled for that date
    /// - Throws: SupabaseError if the operation fails
    func fetchOccurrences(for date: Date) async throws -> [GoalOccurrence]

    /// Fetches occurrences for a date range
    ///
    /// - Parameters:
    ///   - from: Start date (inclusive)
    ///   - to: End date (inclusive)
    /// - Returns: Array of occurrences in the date range
    /// - Throws: SupabaseError if the operation fails
    func fetchOccurrences(from: Date, to: Date) async throws -> [GoalOccurrence]

    /// Fetches a specific occurrence by ID
    ///
    /// - Parameter id: The UUID of the occurrence to fetch
    /// - Returns: The occurrence if found
    /// - Throws: SupabaseError.notFound if occurrence doesn't exist
    func fetch(_ id: UUID) async throws -> GoalOccurrence

    /// Creates a new occurrence
    ///
    /// - Parameter occurrence: The occurrence to create
    /// - Returns: The created occurrence with server-generated fields
    /// - Throws: SupabaseError if the operation fails
    func create(_ occurrence: GoalOccurrence) async throws -> GoalOccurrence

    /// Updates an existing occurrence
    ///
    /// - Parameter occurrence: The occurrence to update
    /// - Throws: SupabaseError if the operation fails
    func update(_ occurrence: GoalOccurrence) async throws

    /// Completes a tick for an occurrence
    ///
    /// Increments the completed_count and updates status if target is reached.
    /// Uses the complete_tick RPC for atomic operation with points tracking.
    ///
    /// - Parameter id: The UUID of the occurrence to complete
    /// - Throws: SupabaseError if the operation fails
    func completeTick(_ id: UUID) async throws

    /// Skips an occurrence
    ///
    /// Marks the occurrence as skipped and records the reason.
    /// Uses the skip_occurrence RPC for proper event logging.
    ///
    /// - Parameters:
    ///   - id: The UUID of the occurrence to skip
    ///   - reason: Optional reason for skipping
    /// - Throws: SupabaseError if the operation fails
    func skip(_ id: UUID, reason: String?) async throws

    /// Renames an occurrence
    ///
    /// Overrides the default title with a custom name for this specific occurrence.
    ///
    /// - Parameters:
    ///   - id: The UUID of the occurrence
    ///   - newName: The new name for this occurrence
    /// - Throws: SupabaseError if the operation fails
    func rename(_ id: UUID, to newName: String) async throws

    /// Ensures an occurrence exists for a goal on a specific date
    ///
    /// Creates the occurrence if it doesn't exist, or returns existing one.
    /// Uses the ensure_occurrence RPC.
    ///
    /// - Parameters:
    ///   - goalId: The UUID of the goal
    ///   - date: The date for the occurrence
    /// - Returns: The occurrence (existing or newly created)
    /// - Throws: SupabaseError if the operation fails
    func ensureOccurrence(for goalId: UUID, on date: Date) async throws -> GoalOccurrence
}
