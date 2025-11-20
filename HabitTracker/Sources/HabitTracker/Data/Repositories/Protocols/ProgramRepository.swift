import Foundation

/// Repository protocol for managing Program entities
///
/// Provides operations for browsing, adopting, and managing habit programs.
/// Programs are pre-defined collections of goals that users can adopt.
public protocol ProgramRepository: Sendable {
    /// Fetches all published programs
    ///
    /// - Returns: Array of programs sorted by popularity or relevance
    /// - Throws: SupabaseError if the operation fails
    func fetchAll() async throws -> [Program]

    /// Fetches official programs only
    ///
    /// - Returns: Array of official programs
    /// - Throws: SupabaseError if the operation fails
    func fetchOfficialPrograms() async throws -> [Program]

    /// Fetches programs by category
    ///
    /// - Parameter category: The category to filter by
    /// - Returns: Array of programs in that category
    /// - Throws: SupabaseError if the operation fails
    func fetchPrograms(by category: ProgramCategory) async throws -> [Program]

    /// Fetches programs by difficulty level
    ///
    /// - Parameter difficulty: The difficulty level to filter by
    /// - Returns: Array of programs at that difficulty level
    /// - Throws: SupabaseError if the operation fails
    func fetchPrograms(byDifficulty difficulty: ProgramDifficulty) async throws -> [Program]

    /// Fetches programs by tag
    ///
    /// - Parameter tag: The tag to search for
    /// - Returns: Array of programs containing that tag
    /// - Throws: SupabaseError if the operation fails
    func fetchPrograms(withTag tag: String) async throws -> [Program]

    /// Fetches a specific program by ID
    ///
    /// - Parameter id: The UUID of the program to fetch
    /// - Returns: The program if found
    /// - Throws: SupabaseError.notFound if program doesn't exist
    func fetch(_ id: UUID) async throws -> Program

    /// Fetches goals associated with a program
    ///
    /// - Parameter programId: The UUID of the program
    /// - Returns: Array of program goals
    /// - Throws: SupabaseError if the operation fails
    func fetchGoals(for programId: UUID) async throws -> [ProgramGoal]

    /// Adopts a program, creating goals from the program's templates
    ///
    /// This creates actual goals for the user based on the program's goal templates.
    ///
    /// - Parameters:
    ///   - programId: The UUID of the program to adopt
    ///   - areaId: Optional area to organize the adopted goals in
    /// - Returns: Array of created goals
    /// - Throws: SupabaseError if the operation fails
    func adoptProgram(programId: UUID, areaId: UUID?) async throws -> [Goal]

    /// Searches programs by title or description
    ///
    /// - Parameter query: The search query
    /// - Returns: Array of programs matching the query
    /// - Throws: SupabaseError if the operation fails
    func search(query: String) async throws -> [Program]

    /// Creates a new program (for admin/author users)
    ///
    /// - Parameter program: The program to create
    /// - Returns: The created program with server-generated fields
    /// - Throws: SupabaseError if the operation fails or user lacks permissions
    func create(_ program: Program) async throws -> Program

    /// Updates an existing program (for admin/author users)
    ///
    /// - Parameter program: The program to update
    /// - Throws: SupabaseError if the operation fails or user lacks permissions
    func update(_ program: Program) async throws

    /// Deletes a program by ID (for admin users only)
    ///
    /// - Parameter id: The UUID of the program to delete
    /// - Throws: SupabaseError if the operation fails or user lacks permissions
    func delete(id: UUID) async throws
}
