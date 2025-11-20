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
    public init() async {
        self.client = await SupabaseService.shared.getClient()
        self.networkMonitor = NetworkMonitor()
    }

    /// MARK: - ProgramRepository Implementation

    public func fetchAll() async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
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

    public func fetchOfficialPrograms() async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
                .eq("is_official", value: true)
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

    public func fetchPrograms(by category: ProgramCategory) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
                .eq("category", value: category.rawValue)
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

    public func fetchPrograms(byDifficulty difficulty: ProgramDifficulty) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
                .eq("difficulty", value: difficulty.rawValue)
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

    public func fetchPrograms(withTag tag: String) async throws -> [Program] {
        do {
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
                .contains("tags", value: [tag])
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

    public func fetch(_ id: UUID) async throws -> Program {
        do {
            let response: ProgramDTO = try await client
                .from("programs")
                .select()
                .eq("id", value: id.uuidString)
                .eq("is_published", value: true)
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
                .from("program_goals")
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

    public func adoptProgram(programId: UUID, areaId: UUID?) async throws -> [Goal] {
        guard let userId = await client.auth.currentUser?.id else {
            throw SupabaseError.unauthorized
        }

        // Fetch the program to verify it exists and is published
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
            let goal = Goal(
                id: UUID(),
                userId: userId,
                areaId: areaId,
                title: programGoal.title,
                emoji: programGoal.emoji,
                notes: "Adopted from program: \(program.title)",
                kind: goalKind,
                status: .active,
                timesPerDay: programGoal.timesPerDay,
                pointsPerCompletion: 10, // Default points
                schedule: nil, // TODO: Parse schedule from schedulePattern
                reminder: nil,
                keepUntilCompleteRollover: false,
                streakCount: 0,
                totalCompleted: 0,
                lastCompletedAt: nil,
                isShared: false,
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
                print("⚠️ Failed to create goal '\(goal.title)' from program: \(error.localizedDescription)")
                throw SupabaseError.from(error)
            } catch {
                print("⚠️ Failed to create goal '\(goal.title)' from program: \(error.localizedDescription)")
                throw SupabaseError.from(error)
            }
        }

        return createdGoals
    }

    public func search(query: String) async throws -> [Program] {
        do {
            // Search in title and description using textSearch
            let response: [ProgramDTO] = try await client
                .from("programs")
                .select()
                .eq("is_published", value: true)
                .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
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
            var dto = ProgramDTO(from: program)
            // Manually set updated_at to current time
            dto = ProgramDTO(
                id: dto.id,
                title: dto.title,
                description: dto.description,
                emoji: dto.emoji,
                imageURL: dto.imageURL,
                category: dto.category,
                difficulty: dto.difficulty,
                durationDays: dto.durationDays,
                tags: dto.tags,
                authorName: dto.authorName,
                isOfficial: dto.isOfficial,
                isPublished: dto.isPublished,
                createdAt: dto.createdAt,
                updatedAt: Date()
            )

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

// MARK: - Extension for DTO Updates

extension ProgramDTO {
    /// Creates a new ProgramDTO with all fields
    ///
    /// Used for updates where we need to manually set updated_at
    init(
        id: UUID,
        title: String,
        description: String,
        emoji: String?,
        imageURL: String?,
        category: String,
        difficulty: String,
        durationDays: Int?,
        tags: [String],
        authorName: String?,
        isOfficial: Bool,
        isPublished: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.imageURL = imageURL
        self.category = category
        self.difficulty = difficulty
        self.durationDays = durationDays
        self.tags = tags
        self.authorName = authorName
        self.isOfficial = isOfficial
        self.isPublished = isPublished
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
