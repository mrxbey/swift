---
name: supabase-integration
description: Integrates Supabase backend with Swift applications. Use when setting up Supabase client, implementing repositories, configuring RLS policies, writing SQL queries, or debugging Supabase connections. Keywords supabase, postgresql, rls, postgrest, realtime, edge functions, database queries, auth.uid().
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Supabase Integration for Swift

Handles all aspects of Supabase integration in this HabitTracker Swift project.

## When to Use

Activate this skill when:
- Setting up Supabase Swift SDK
- Implementing repository layer with Supabase
- Writing or debugging SQL queries
- Configuring Row Level Security (RLS)
- Setting up Realtime subscriptions
- Working with Edge Functions
- Debugging authentication issues
- User mentions "supabase", "database", "backend", "sql", "rls"

## Project Context

**This Project:**
- HabitTracker iOS/macOS app
- Swift 6.2 with strict concurrency
- Supabase PostgreSQL 15+ backend
- Complete schema in `/HabitTracker/Supabase/migrations/`
- TCA architecture with repository pattern

**Database Schema:**
- 25+ tables with RLS enabled
- 4 migrations (schema, RLS, triggers/RPCs, indexes)
- Optimized for auth.uid() lookups
- Buddy system (shared goals)
- Versioned measure targets (water tracking)

## Instructions

### 1. Setting Up Supabase Client

**Create SupabaseClient configuration:**

```swift
// Infrastructure/Network/SupabaseClient.swift
import Supabase

actor SupabaseService: Sendable {
    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        guard let url = URL(string: Config.supabaseURL),
              let key = Config.supabaseAnonKey else {
            fatalError("Supabase configuration missing")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: AuthClientOptions(
                    autoRefreshToken: true,
                    persistSession: true,
                    storage: UserDefaults.standard
                ),
                global: GlobalOptions(
                    headers: ["apikey": key]
                )
            )
        )
    }

    func getClient() -> SupabaseClient {
        client
    }
}
```

**Configuration file (gitignored):**

```swift
// Config.swift (add to .gitignore)
enum Config {
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "YOUR_ANON_KEY"
}
```

### 2. Implementing Repositories

**Repository protocol:**

```swift
protocol GoalRepository: Sendable {
    func fetchAll() async throws -> [Goal]
    func fetch(_ id: UUID) async throws -> Goal
    func create(_ goal: Goal) async throws -> Goal
    func update(_ goal: Goal) async throws
    func delete(id: UUID) async throws
}
```

**Supabase implementation:**

```swift
actor SupabaseGoalRepository: GoalRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseService.shared.getClient()) {
        self.client = client
    }

    func fetchAll() async throws -> [Goal] {
        let response: [GoalDTO] = try await client
            .from("goals")
            .select()
            .eq("user_id", value: client.auth.currentUser?.id ?? "")
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value

        return response.map(\.toDomain)
    }

    func create(_ goal: Goal) async throws -> Goal {
        let dto = GoalDTO(from: goal)
        let response: GoalDTO = try await client
            .from("goals")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value

        return response.toDomain
    }
}
```

### 3. Data Transfer Objects (DTOs)

**Map between database and domain models:**

```swift
struct GoalDTO: Codable {
    let id: UUID
    let userId: UUID
    let areaId: UUID
    let title: String
    let emoji: String?
    let kind: String
    let status: String
    let keepUntilComplete: Bool
    let timesPerDay: Int
    let pointsPerCompletion: Int
    let linkedExerciseKey: String?
    let hashtags: [String]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, emoji, kind, status, hashtags
        case userId = "user_id"
        case areaId = "area_id"
        case keepUntilComplete = "keep_until_complete"
        case timesPerDay = "times_per_day"
        case pointsPerCompletion = "points_per_completion"
        case linkedExerciseKey = "linked_exercise_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from goal: Goal) {
        self.id = goal.id
        self.userId = goal.userId
        self.areaId = goal.areaId
        self.title = goal.title
        self.emoji = goal.emoji
        self.kind = goal.kind.rawValue
        self.status = goal.status.rawValue
        self.keepUntilComplete = goal.keepUntilComplete
        self.timesPerDay = goal.timesPerDay
        self.pointsPerCompletion = goal.pointsPerCompletion
        self.linkedExerciseKey = goal.linkedExerciseKey?.rawValue
        self.hashtags = goal.hashtags
        self.createdAt = goal.createdAt
        self.updatedAt = goal.updatedAt
    }

    var toDomain: Goal {
        Goal(
            id: id,
            userId: userId,
            areaId: areaId,
            title: title,
            emoji: emoji,
            kind: GoalKind(rawValue: kind) ?? .habit,
            status: GoalStatus(rawValue: status) ?? .active,
            keepUntilComplete: keepUntilComplete,
            timesPerDay: timesPerDay,
            pointsPerCompletion: pointsPerCompletion,
            linkedExerciseKey: linkedExerciseKey.flatMap { LinkedExercise(rawValue: $0) },
            hashtags: hashtags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

### 4. Calling RPCs (Remote Procedure Calls)

**This project has 12 RPCs (see migration 003):**

```swift
// Complete a tick
func completeTick(_ occurrenceId: UUID) async throws {
    try await client.rpc(
        "complete_tick",
        params: [
            "p_occ": occurrenceId,
            "p_user": client.auth.currentUser?.id ?? ""
        ]
    ).execute()
}

// Get current streak
func getCurrentStreak() async throws -> Int {
    let response: Int = try await client.rpc(
        "get_current_streak"
    ).single().execute().value

    return response
}

// Get water progress
func getWaterProgress(goalId: UUID, from: Date, to: Date) async throws -> [WaterDataPoint] {
    struct WaterRow: Codable {
        let day: Date
        let consumed: Double
        let target: Double
        let unit: String
    }

    let response: [WaterRow] = try await client.rpc(
        "get_water_progress",
        params: [
            "p_goal": goalId,
            "p_from": from,
            "p_to": to
        ]
    ).execute().value

    return response.map { row in
        WaterDataPoint(
            date: row.day,
            consumed: row.consumed,
            target: row.target,
            unit: UnitKind(rawValue: row.unit) ?? .ml
        )
    }
}
```

### 5. Realtime Subscriptions

**Subscribe to changes:**

```swift
func subscribeToOccurrences(userId: UUID) -> AsyncStream<GoalOccurrence> {
    AsyncStream { continuation in
        Task {
            let channel = await client.channel("occurrences:\(userId)")

            await channel
                .on(
                    .postgresChange(
                        event: .all,
                        schema: "public",
                        table: "goal_occurrences",
                        filter: "user_id=eq.\(userId)"
                    )
                ) { payload in
                    if let occurrence = try? JSONDecoder().decode(
                        OccurrenceDTO.self,
                        from: JSONEncoder().encode(payload.new)
                    ) {
                        continuation.yield(occurrence.toDomain)
                    }
                }
                .subscribe()
        }
    }
}
```

### 6. Error Handling

**Supabase-specific errors:**

```swift
enum SupabaseError: LocalizedError {
    case unauthorized
    case networkError(Error)
    case decodingError(Error)
    case rlsViolation
    case notFound

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to continue"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data format error: \(error.localizedDescription)"
        case .rlsViolation:
            return "Permission denied"
        case .notFound:
            return "Resource not found"
        }
    }
}

// Usage
do {
    let goals = try await repository.fetchAll()
} catch let error as PostgrestError {
    if error.code == "PGRST301" {
        throw SupabaseError.rlsViolation
    } else {
        throw SupabaseError.networkError(error)
    }
} catch {
    throw SupabaseError.networkError(error)
}
```

## Database Schema Reference

**Key tables in this project:**

1. **profiles** - User profiles with timezone
2. **areas** - Life areas for organizing goals
3. **goals** - Habits, tasks, measured goals
4. **goal_schedules** - Recurrence patterns (ISO 8601 weekdays)
5. **goal_occurrences** - Daily instances
6. **goal_members** - Buddy system
7. **occurrence_member_status** - Per-member completion
8. **measurements** - Water/count tracking
9. **daily_summary** - Materialized stats

**See:** `/HabitTracker/Supabase/migrations/` for complete schema

## RLS (Row Level Security)

**This project uses RLS on ALL tables.**

**Common patterns:**

```sql
-- Owner-only access
CREATE POLICY "Users can view own goals"
    ON goals FOR SELECT
    USING (user_id = auth.uid());

-- Shared access (buddy system)
CREATE POLICY "Members can view shared goals"
    ON goals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goal_members
            WHERE goal_id = goals.id
            AND user_id = auth.uid()
        )
    );
```

**Testing RLS in SQL:**

```sql
-- Test as specific user
SET LOCAL jwt.claims.sub = 'user-uuid-here';
SELECT * FROM goals;  -- Should only see own goals
```

## Best Practices

### DO:
✅ Use actors for repository implementations (thread-safe)
✅ Map between DTOs and domain models
✅ Handle errors gracefully
✅ Use snake_case for database columns, camelCase in Swift
✅ Leverage RPCs for complex operations
✅ Subscribe to Realtime for live updates
✅ Index columns used in WHERE clauses (especially auth.uid())
✅ Test RLS policies thoroughly

### DON'T:
❌ Expose Supabase client directly to views
❌ Hardcode URLs or keys
❌ Skip error handling
❌ Forget to unsubscribe from Realtime channels
❌ Make N+1 queries (use joins or select with related data)
❌ Skip RLS on any public table
❌ Use `.execute()` without checking response

## Debugging

**Common issues:**

1. **RLS blocking queries:**
   - Check user is authenticated
   - Verify RLS policies
   - Test with SET LOCAL in SQL

2. **Decoding errors:**
   - Check column names match CodingKeys
   - Verify date formats (ISO 8601)
   - Check for null values

3. **Connection issues:**
   - Verify URL and anon key
   - Check network connectivity
   - Test with Postman/curl

4. **Performance:**
   - Add indexes for filtered columns
   - Use covering indexes
   - Materialize computed values (daily_summary)

## Environment Variables Needed

Ask user for:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your anon/public key
- `SUPABASE_SERVICE_ROLE_KEY` - For admin operations (if needed)

## Next Steps Checklist

When implementing Supabase integration:

- [ ] Create Config.swift with environment variables
- [ ] Set up SupabaseService actor
- [ ] Implement repository protocols
- [ ] Create DTOs for all tables
- [ ] Add RPC call methods
- [ ] Set up Realtime subscriptions
- [ ] Add comprehensive error handling
- [ ] Write repository tests
- [ ] Document env variables in README
- [ ] Add .env.example file

## Examples

### Example 1: Fetch Today's Occurrences

```swift
actor SupabaseOccurrenceRepository: OccurrenceRepository {
    func fetchToday() async throws -> [GoalOccurrence] {
        let today = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        let response: [OccurrenceDTO] = try await client
            .from("goal_occurrences")
            .select()
            .eq("user_id", value: client.auth.currentUser?.id ?? "")
            .eq("scheduled_date", value: formatter.string(from: today))
            .order("created_at", ascending: true)
            .execute()
            .value

        return response.map(\.toDomain)
    }
}
```

### Example 2: Create Area with Error Handling

```swift
func create(_ area: Area) async throws -> Area {
    let dto = AreaDTO(from: area)

    do {
        let response: AreaDTO = try await client
            .from("areas")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value

        return response.toDomain
    } catch let error as PostgrestError {
        if error.message?.contains("duplicate") == true {
            throw AreaError.duplicateName
        } else {
            throw SupabaseError.networkError(error)
        }
    }
}
```

### Example 3: Complex Query with Joins

```swift
// Get goals with their area information
func fetchGoalsWithAreas() async throws -> [(Goal, Area)] {
    struct GoalWithArea: Codable {
        let goal: GoalDTO
        let area: AreaDTO
    }

    let response: [GoalWithArea] = try await client
        .from("goals")
        .select("""
            *,
            area:areas(*)
        """)
        .eq("user_id", value: client.auth.currentUser?.id ?? "")
        .execute()
        .value

    return response.map { ($0.goal.toDomain, $0.area.toDomain) }
}
```

## Related Skills

- **swift-development** - Swift coding patterns
- **tca-development** - TCA repository integration
- **skill-creator** - Create new Supabase-related skills as needed
