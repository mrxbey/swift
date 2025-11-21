import Foundation
import Supabase

/// Supabase implementation of ProgramRepository
///
/// Thread-safe actor that handles all program-related database operations.
/// Programs are public content, so caching strategy is different from user-specific data.
public actor SupabaseProgramRepository: ProgramRepository {
    private let client: SupabaseClient
    private let networkMonitor: NetworkMonitor

    /// MARK: - Initialization

    public init(
        client: SupabaseClient,
        networkMonitor: NetworkMonitor
    ) {
        self.client = client
        self.networkMonitor = networkMonitor
    }

    /// Convenience initializer using shared services
    ///
    /// - Throws: SupabaseError if client configuration is invalid
    public init() async throws {
        self.client = try await SupabaseService.shared.getClient()
        self.networkMonitor = NetworkMonitor()
    }

    /// MARK: - ProgramRepository Implementation

    public func fetchAll() async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("visibility", value: "public")
                .order("added_count", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchPrograms(by visibility: ProgramVisibility) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("visibility", value: visibility.rawValue)
                .order("added_count", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchPrograms(by category: String) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("visibility", value: "public")
                .eq("category", value: category)
                .order("added_count", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetchPrograms(withTag tag: String) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("visibility", value: "public")
                .contains("tags", value: [tag])
                .order("added_count", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func fetch(_ id: UUID) async throws -> Program {
        do {
            let response: ProgramDTO = try await client
                .from("programs")
                .select()
                .eq("id", value: id.uuidString)
                .eq("visibility", value: "public")
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

    public func fetch(slug: String) async throws -> Program {
        do {
            let response: ProgramDTO = try await client
                .from("programs")
                .select()
                .eq("slug", value: slug)
                .eq("visibility", value: "public")
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

    public func fetchGoals(for programId: UUID) async throws -> [ProgramGoal] {
        do {
            let response: [ProgramGoalDTO] = try await client
                .from("program_items")
                .select()
                .eq("program_id", value: programId.uuidString)
                .order("order_index", ascending: true)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func adoptProgram(programId: UUID, areaId: UUID) async throws -> [Goal] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Fetch the program to verify it exists and is public
        let program = try await fetch(programId)

        // Fetch the program's goal templates
        let programGoals = try await fetchGoals(for: programId)

        // Create actual goals from templates
        var createdGoals: [Goal] = []

        for programGoal in programGoals {
            // Parse the goal kind from the template
            let goalKind: GoalKind
            switch programGoal.kind.lowercased() {
            case "habit":
                goalKind = .habit
            case "task":
                goalKind = .task
            case "measure":
                goalKind = .measure
            default:
                goalKind = .habit // Default to habit if unknown
            }

            // Create a new goal from the template
            // Note: areaId is required (database constraint: NOT NULL)
            let goal = Goal(
                id: UUID(),
                userId: userId,
                areaId: areaId,
                title: programGoal.title,
                emoji: programGoal.emoji,
                kind: goalKind,
                status: .active,
                keepUntilComplete: false,
                timesPerDay: nil,
                pointsPerCompletion: programGoal.defaultPoints,
                linkedExerciseKey: programGoal.linkedExerciseKey,
                hashtags: [],
                createdAt: Date(),
                updatedAt: Date()
            )

            // Insert the goal using Supabase
            do {
                let dto = GoalDTO(from: goal)

                let response: GoalDTO = try await client
                    .from("goals")
                    .insert(dto)
                    .select()
                    .single()
                    .execute()
                    .value

                createdGoals.append(response.toDomain)
            } catch let error as PostgrestError {
                // Log error but continue with other goals
                throw SupabaseError.from(error)
            } catch {
                throw SupabaseError.from(error)
            }
        }

        return createdGoals
    }

    public func search(query: String) async throws -> [Program] {
        do {
            // Search in title and summary using textSearch
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("visibility", value: "public")
                .or("title.ilike.%\(query)%,summary.ilike.%\(query)%")
                .order("added_count", ascending: false)
                .execute()
                .value

            return response.map(\.toDomain)
        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }

    public func create(_ program: Program) async throws -> Program {
        guard await client.auth.currentUser?.id != nil else {
            throw SupabaseError.unauthorized
        }

        // Note: In production, you would check if the user has permission to create programs
        // This might involve checking a user role or permission table

        do {
            let dto = ProgramDTO(from: program)

            let response: ProgramDTO = try await client
                .from("programs")
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

    public func update(_ program: Program) async throws {
        guard await client.auth.currentUser?.id != nil else {
            throw SupabaseError.unauthorized
        }

        // Note: In production, you would check if the user has permission to update this program
        // This might involve checking if they're the author or an admin

        do {
            let dto = ProgramDTO(from: program)

            let _: ProgramDTO = try await client
                .from("programs")
                .update(dto)
                .eq("id", value: program.id.uuidString)
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
        guard await client.auth.currentUser?.id != nil else {
            throw SupabaseError.unauthorized
        }

        // Note: In production, you would check if the user has admin permissions

        do {
            try await client
                .from("programs")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

        } catch let error as PostgrestError {
            throw SupabaseError.from(error)
        } catch {
            throw SupabaseError.from(error)
        }
    }
}
