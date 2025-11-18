# Next Steps: Supabase Client Integration

**Created:** November 18, 2025
**Status:** Ready to Begin
**Estimated Time:** 2-3 hours

---

## 🎯 Goal

Implement complete Supabase backend integration for HabitTracker, connecting the SwiftUI views to the PostgreSQL database with full CRUD operations, RLS security, and offline sync.

---

## ✅ Prerequisites (DONE)

- [x] Database schema (4 migrations)
- [x] Domain models (Goal, Area, GoalOccurrence, etc.)
- [x] SwiftUI views (all 5 main features)
- [x] TCA features (state management)
- [x] Design system
- [x] Claude Code Skills

---

## 📋 Required Environment Variables

### **Please provide:**

1. **SUPABASE_URL**
   - Your Supabase project URL
   - Format: `https://xxxxxxxxxxxxx.supabase.co`

2. **SUPABASE_ANON_KEY**
   - Your anon/public API key
   - Format: Long JWT token starting with `eyJ...`

3. **SUPABASE_SERVICE_ROLE_KEY** (optional, for admin operations)
   - Format: Long JWT token starting with `eyJ...`

**Where to find these:**
- Go to your Supabase project dashboard
- Settings → API
- Copy "Project URL" and "anon public" key

---

## 🏗️ Implementation Plan

### Phase 1: Foundation (30 minutes)

#### 1.1 Configuration Setup

**Create files:**
- `Config.swift` (environment variables)
- `.env.example` (template)
- `SupabaseService.swift` (singleton client)

**Tasks:**
- [ ] Add Config.swift to Package.swift as resource
- [ ] Create SupabaseService actor
- [ ] Test connection with simple query
- [ ] Add error handling

#### 1.2 Data Transfer Objects (DTOs)

**Create DTOs for all models:**
- [ ] AreaDTO
- [ ] GoalDTO
- [ ] GoalScheduleDTO
- [ ] GoalOccurrenceDTO
- [ ] MeasurementDTO
- [ ] ReflectionDTO
- [ ] ProgramDTO

**Each DTO needs:**
- CodingKeys for snake_case ↔ camelCase
- init(from: DomainModel)
- var toDomain: DomainModel

### Phase 2: Repository Layer (60 minutes)

#### 2.1 Repository Protocols

**Already defined, implement:**
- [ ] AreaRepository
- [ ] GoalRepository
- [ ] OccurrenceRepository
- [ ] MeasurementRepository
- [ ] ReflectionRepository
- [ ] ProgramRepository

#### 2.2 Supabase Implementations

**For each repository create:**
- [ ] Actor-based implementation
- [ ] CRUD operations
- [ ] RPC method calls
- [ ] Error handling
- [ ] Query optimization

**Example pattern:**
```swift
actor SupabaseGoalRepository: GoalRepository {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAll() async throws -> [Goal] {
        let response: [GoalDTO] = try await client
            .from("goals")
            .select()
            .eq("user_id", value: auth.uid)
            .eq("status", value: "active")
            .execute()
            .value

        return response.map(\.toDomain)
    }
}
```

#### 2.3 RPC Wrappers

**Implement wrappers for all 12 RPCs:**
- [ ] complete_tick
- [ ] skip_occurrence
- [ ] rename_occurrence
- [ ] ensure_occurrence
- [ ] set_measure_target
- [ ] add_measurement
- [ ] get_water_progress
- [ ] get_current_streak
- [ ] get_longest_streak
- [ ] get_most_completed_goals
- [ ] get_area_statistics
- [ ] search_by_hashtag

### Phase 3: Dependency Registration (20 minutes)

#### 3.1 TCA Dependencies

**Register all repositories:**

```swift
// DependencyValues+Repositories.swift

extension DependencyValues {
    var goalRepository: GoalRepository {
        get { self[GoalRepositoryKey.self] }
        set { self[GoalRepositoryKey.self] = newValue }
    }
}

private enum GoalRepositoryKey: DependencyKey {
    static let liveValue: GoalRepository = SupabaseGoalRepository(
        client: SupabaseService.shared.getClient()
    )
    static let testValue: GoalRepository = MockGoalRepository()
}
```

#### 3.2 Mock Repositories

**Create mocks for testing:**
- [ ] MockGoalRepository
- [ ] MockAreaRepository
- [ ] MockOccurrenceRepository

### Phase 4: Feature Integration (40 minutes)

#### 4.1 Update TCA Features

**Wire real repositories into features:**

**TodayFeature:**
- [ ] Replace mock with real OccurrenceRepository
- [ ] Implement fetchToday() call
- [ ] Implement completeTick RPC
- [ ] Implement skip RPC
- [ ] Test data flow

**AreasFeature:**
- [ ] Replace mock with real AreaRepository
- [ ] Implement CRUD operations
- [ ] Test area creation/deletion

**InsightsFeature:**
- [ ] Implement streak RPCs
- [ ] Implement analytics queries
- [ ] Fetch top goals

**ProgramsFeature:**
- [ ] Fetch programs catalog
- [ ] Implement program adoption

**SettingsFeature:**
- [ ] Profile fetching
- [ ] Sync operations

#### 4.2 Error Handling

**Global error handling:**
- [ ] Create SupabaseError enum
- [ ] Map PostgrestError to user-friendly messages
- [ ] Add retry logic for network errors
- [ ] Handle RLS violations gracefully

### Phase 5: Offline Support (30 minutes)

#### 5.1 Local Cache

**SwiftData integration:**
- [ ] Create SwiftData models (mirror DTOs)
- [ ] Implement cache layer
- [ ] Cache-first reads
- [ ] Background sync

#### 5.2 Sync Engine

**Delta sync:**
- [ ] Track lastSyncTimestamp
- [ ] Fetch updated_at > lastSync
- [ ] Merge conflicts (last-write-wins)
- [ ] Queue offline writes

### Phase 6: Realtime (20 minutes)

#### 6.1 Subscriptions

**Subscribe to changes:**
- [ ] Occurrences channel (for today view)
- [ ] Goals channel (for areas view)
- [ ] Members channel (for buddy updates)

#### 6.2 Live Updates

**Handle realtime events:**
- [ ] Insert events → add to local state
- [ ] Update events → modify local state
- [ ] Delete events → remove from local state

---

## 📂 File Structure

```
HabitTracker/Sources/HabitTracker/
├── Infrastructure/
│   ├── Config.swift                    ← NEW
│   ├── Network/
│   │   ├── SupabaseService.swift       ← NEW
│   │   ├── SupabaseError.swift         ← NEW
│   │   └── RealtimeService.swift       ← NEW
├── Data/
│   ├── DTOs/
│   │   ├── AreaDTO.swift               ← NEW
│   │   ├── GoalDTO.swift               ← NEW
│   │   ├── OccurrenceDTO.swift         ← NEW
│   │   ├── MeasurementDTO.swift        ← NEW
│   │   ├── ReflectionDTO.swift         ← NEW
│   │   └── ProgramDTO.swift            ← NEW
│   ├── Repositories/
│   │   ├── Protocols/
│   │   │   ├── AreaRepository.swift    ← EXISTS (update)
│   │   │   ├── GoalRepository.swift    ← EXISTS (update)
│   │   │   └── ...                     ← EXISTS
│   │   ├── Supabase/
│   │   │   ├── SupabaseAreaRepo.swift  ← NEW
│   │   │   ├── SupabaseGoalRepo.swift  ← NEW
│   │   │   └── ...                     ← NEW
│   │   └── Mock/
│   │       ├── MockAreaRepo.swift      ← NEW
│   │       └── ...                     ← NEW
│   ├── Local/
│   │   ├── SwiftDataModels/            ← NEW
│   │   ├── CacheService.swift          ← NEW
│   │   └── SyncEngine.swift            ← NEW
│   └── Dependencies/
│       └── DependencyValues+Repos.swift ← NEW
├── Domain/                             ← EXISTS
└── Features/                           ← EXISTS (update to use real repos)
```

---

## 🧪 Testing Strategy

### Unit Tests

**For each repository:**
- [ ] Test CRUD operations
- [ ] Test RPC calls
- [ ] Test error handling
- [ ] Test DTO conversions

### Integration Tests

- [ ] Test TCA features with real repositories
- [ ] Test offline → online sync
- [ ] Test Realtime subscriptions
- [ ] Test RLS policies

### Manual Testing

- [ ] Create area
- [ ] Create goal
- [ ] Complete occurrence
- [ ] Check points awarded
- [ ] Verify Realtime updates
- [ ] Test offline mode

---

## 🔐 Security Checklist

- [ ] Config.swift in .gitignore
- [ ] .env in .gitignore
- [ ] .env.example committed (no secrets)
- [ ] RLS tested for all operations
- [ ] No hardcoded keys in code
- [ ] User auth required for all queries
- [ ] Test with multiple user accounts

---

## 📊 Success Criteria

**Phase 1 Complete When:**
- ✅ Can connect to Supabase
- ✅ Can query one table successfully
- ✅ Errors are handled gracefully

**Phase 2 Complete When:**
- ✅ All repositories implemented
- ✅ All CRUD operations work
- ✅ All RPCs callable

**Phase 3 Complete When:**
- ✅ Dependencies registered
- ✅ Mocks available for testing

**Phase 4 Complete When:**
- ✅ Today view shows real data
- ✅ Can create/complete goals
- ✅ Areas CRUD works
- ✅ Insights show real analytics

**Phase 5 Complete When:**
- ✅ Offline mode works
- ✅ Sync doesn't lose data
- ✅ Conflicts resolved

**Phase 6 Complete When:**
- ✅ Live updates appear
- ✅ Buddy updates show
- ✅ No duplicate events

---

## 🎯 Immediate Next Actions

### Action 1: Get Environment Variables

**I need from you:**
```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxxxxxx...
```

### Action 2: Verify Database

**Run these queries to verify schema:**
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
SELECT * FROM goals LIMIT 1;
SELECT * FROM areas LIMIT 1;
```

### Action 3: Test Authentication

**Create a test user:**
- Sign in with Apple (or Email)
- Verify user appears in `auth.users`
- Verify profile created in `profiles`

---

## 🚀 Implementation Order

**Recommended sequence:**

1. **Start:** Config + SupabaseService (15 min)
2. **Then:** AreaDTO + AreaRepository (20 min)
3. **Test:** Create/fetch areas from Today tab (5 min)
4. **Then:** GoalDTO + GoalRepository (25 min)
5. **Then:** OccurrenceDTO + OccurrenceRepository (25 min)
6. **Test:** Today view with real data (10 min)
7. **Then:** Other DTOs + Repositories (30 min)
8. **Then:** RPC wrappers (20 min)
9. **Then:** Realtime subscriptions (20 min)
10. **Then:** Offline sync (30 min)
11. **Test:** End-to-end user flow (30 min)

**Total:** ~3.5 hours

---

## 💡 Tips

### Performance
- Use `.select("*")` to get all columns (faster than listing)
- Use covering indexes (already in migration 004)
- Batch operations when possible
- Cache frequently-accessed data

### Error Handling
- Always use TaskResult for async operations
- Provide user-friendly error messages
- Log errors for debugging
- Retry network errors with exponential backoff

### Best Practices
- Keep DTOs separate from domain models
- Use actors for thread safety
- Test RLS policies thoroughly
- Never expose Supabase client to views
- Use dependency injection everywhere

---

## 🆘 Troubleshooting

**Issue: Can't connect to Supabase**
- Check URL format (include https://)
- Verify anon key is correct
- Test with Postman/curl first

**Issue: RLS blocking queries**
- Check user is authenticated
- Test query in Supabase SQL editor with SET LOCAL
- Verify policy allows operation

**Issue: Decoding errors**
- Check CodingKeys match database columns
- Verify date format (ISO 8601)
- Check for null values

**Issue: Performance slow**
- Add indexes (already in migration 004)
- Use select with specific columns
- Implement pagination for large datasets

---

## 📚 Resources

**Supabase Swift SDK:**
- [Official Docs](https://supabase.com/docs/reference/swift)
- [GitHub](https://github.com/supabase/supabase-swift)

**This Project:**
- Database: `/HabitTracker/Supabase/migrations/`
- Skills: `.claude/skills/supabase-integration/SKILL.md`
- Arch: `ARCHITECTURE.md`

**TCA:**
- [TCA Docs](https://github.com/pointfreeco/swift-composable-architecture)

---

## ✅ Ready to Start?

**Before we begin, I need:**

1. Your Supabase project URL
2. Your Supabase anon key
3. Confirmation that migrations are applied

**Then I will:**

1. Create Config.swift
2. Set up SupabaseService
3. Implement first repository (Areas)
4. Test connection end-to-end
5. Continue with remaining repositories

**Estimated total time: 2-3 hours for complete integration**

---

**Status:** ⏸️ Waiting for environment variables
**Next:** Provide SUPABASE_URL and SUPABASE_ANON_KEY to continue
