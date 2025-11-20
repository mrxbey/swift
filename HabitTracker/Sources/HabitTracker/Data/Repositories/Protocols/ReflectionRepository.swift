import Foundation

/// Repository protocol for managing Reflection entities
///
/// Provides CRUD operations and queries for user reflections across different contexts.
/// Reflections can be scoped to goals, areas, or be general journal entries.
public protocol ReflectionRepository: Sendable {
    /// Fetches all reflections for the current user
    ///
    /// - Returns: Array of reflections sorted by reflection date (newest first)
    /// - Throws: SupabaseError if the operation fails
    func fetchAll() async throws -> [Reflection]

    /// Fetches reflections for a specific goal
    ///
    /// - Parameter goalId: The UUID of the goal
    /// - Returns: Array of reflections for that goal
    /// - Throws: SupabaseError if the operation fails
    func fetchReflections(for goalId: UUID) async throws -> [Reflection]

    /// Fetches reflections for a specific area
    ///
    /// - Parameter areaId: The UUID of the area
    /// - Returns: Array of reflections for that area
    /// - Throws: SupabaseError if the operation fails
    func fetchReflections(forArea areaId: UUID) async throws -> [Reflection]

    /// Fetches reflections within a date range
    ///
    /// - Parameters:
    ///   - startDate: The start of the date range
    ///   - endDate: The end of the date range
    /// - Returns: Array of reflections within the date range
    /// - Throws: SupabaseError if the operation fails
    func fetchReflections(from startDate: Date, to endDate: Date) async throws -> [Reflection]

    /// Fetches reflections by mood
    ///
    /// - Parameter mood: The mood to filter by
    /// - Returns: Array of reflections with that mood
    /// - Throws: SupabaseError if the operation fails
    func fetchReflections(withMood mood: ReflectionMood) async throws -> [Reflection]

    /// Fetches reflections by tag
    ///
    /// - Parameter tag: The tag to search for
    /// - Returns: Array of reflections containing that tag
    /// - Throws: SupabaseError if the operation fails
    func fetchReflections(withTag tag: String) async throws -> [Reflection]

    /// Fetches a specific reflection by ID
    ///
    /// - Parameter id: The UUID of the reflection to fetch
    /// - Returns: The reflection if found
    /// - Throws: SupabaseError.notFound if reflection doesn't exist
    func fetch(_ id: UUID) async throws -> Reflection

    /// Creates a new reflection
    ///
    /// - Parameter reflection: The reflection to create
    /// - Returns: The created reflection with server-generated fields
    /// - Throws: SupabaseError if the operation fails
    func create(_ reflection: Reflection) async throws -> Reflection

    /// Updates an existing reflection
    ///
    /// - Parameter reflection: The reflection to update
    /// - Throws: SupabaseError if the operation fails
    func update(_ reflection: Reflection) async throws

    /// Deletes a reflection by ID
    ///
    /// - Parameter id: The UUID of the reflection to delete
    /// - Throws: SupabaseError if the operation fails
    func delete(id: UUID) async throws

    /// Searches reflections by content text
    ///
    /// - Parameter query: The search query
    /// - Returns: Array of reflections matching the query
    /// - Throws: SupabaseError if the operation fails
    func search(query: String) async throws -> [Reflection]
}
