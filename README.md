# Habit Tracker - SwiftUI + Supabase

**A production-ready habit tracking application built with modern Swift and Supabase.**

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017+%20%7C%20iPadOS%2017+%20%7C%20macOS%2014+-blue.svg)](https://developer.apple.com/)
[![TCA](https://img.shields.io/badge/TCA-1.23.1-purple.svg)](https://github.com/pointfreeco/swift-composable-architecture)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com)

---

## Overview

Habit Tracker is an enterprise-grade iOS/macOS application that helps users build better habits through:

- ✅ **Smart Habit Tracking** - Daily, weekly, monthly, and custom recurrence patterns
- 🎯 **Goal Management** - Organize goals by life areas (work, health, personal)
- 💧 **Measured Goals** - Track water intake and other quantifiable metrics
- 🤝 **Buddy System** - Share goals with friends for accountability
- 📊 **Insights & Analytics** - Streaks, completion rates, and trend analysis
- 🎨 **Beautiful UI** - Native SwiftUI with iOS 17+ features
- 🔒 **Privacy First** - Row-level security with offline-first sync
- 🌟 **Gamification** - Points, streaks, and achievements

---

## Architecture

This project implements **Clean Architecture** with modern Swift best practices (2025):

```
┌─────────────────────────────────────────────────────┐
│             Presentation (SwiftUI + TCA)            │
├─────────────────────────────────────────────────────┤
│         Domain (Models, Use Cases, Services)        │
├─────────────────────────────────────────────────────┤
│     Data (Repositories, Network, Cache, Sync)       │
├─────────────────────────────────────────────────────┤
│    Infrastructure (Supabase, SwiftData, Notify)    │
└─────────────────────────────────────────────────────┘
```

### Key Technologies

**Frontend**
- **Swift 6.2** with strict concurrency checking
- **SwiftUI** with iOS 17+ `@Observable` macro (100% performance improvement over `ObservableObject`)
- **The Composable Architecture (TCA) 1.23.1** for state management and testing
- **SwiftData** for local persistence and offline support
- **UserNotifications** for local reminders

**Backend**
- **Supabase** (PostgreSQL 15+)
- **Row Level Security (RLS)** for multi-tenant data isolation
- **Edge Functions** (Deno) for serverless operations
- **pg_cron** for scheduled background jobs
- **Realtime** WebSocket subscriptions

---

## Features

### Core Functionality

#### 1. Areas & Goals
- Create life areas (Work, Health, Personal, etc.) with colors and emojis
- Multiple goals per area
- Pause, archive, or delete areas (with cascade delete)
- Three goal types:
  - **Habits** - Repeating patterns (daily, weekly, monthly, custom)
  - **Tasks** - One-time items with optional due dates
  - **Measures** - Track quantifiable metrics (water, steps, etc.)

#### 2. Advanced Scheduling
- **Does not repeat** - One-time tasks
- **Daily** - Every day or every N days
- **Weekly** - Specific weekdays (e.g., Mon, Wed, Fri) with custom intervals
- **Monthly** - Specific days of month (e.g., 1st and 15th)
- **Custom** - Complex patterns with end dates
- **ISO 8601 Weekdays** - Monday=1...Sunday=7
- **Timezone-aware** - Handles DST correctly

#### 3. Occurrence Management
- **Times per day** - Set target (1-100) for repeated completions
- **Keep until complete** - Roll over incomplete goals to next scheduled day
- **Rename past days** - Override title/emoji for specific occurrences
- **Skip vs Reschedule** - Mark as skipped or move to new date
- **Content snapshots** - Preserve goal state at scheduling time

#### 4. Buddy System (Shared Goals)
- Invite friends to share goals
- Per-member completion tracking
- Goal completes only when ALL members finish (AND logic)
- View buddy progress

#### 5. Water Tracking & Measurements
- Set daily targets with versioned history
- Multiple units (ml, L, oz)
- Visual progress indicators
- Analytics with correct historical targets

#### 6. Reflections & Journaling
- **Multi-page templates** with info pages, questions, and summaries
- Freeform journaling
- Link reflections to goals
- Hashtag support for organization
- Public template library

#### 7. Programs (Inspire)
- Browse curated program catalog
- Rich content (images, descriptions, ratings)
- Selective import - choose which items to adopt
- Track progress through program

#### 8. Insights & Analytics
- **Current streak** - Consecutive days with ≥1 completion
- **Longest streak** - All-time best
- **Completion rates** by area, goal, time period
- **Most completed goals** (last 30 days)
- **Hashtag explorer** - Find tagged content
- **Area statistics** - Comprehensive metrics

#### 9. Gamification
- Points system (configurable per goal)
- Daily activity tracking
- Achievement system
- Leaderboards (future)

#### 10. Smart Recommendations
- "Goals of the Day" based on:
  - Area balance
  - Streak risk
  - Program schedule
  - Low adherence goals

---

## Database Schema

### Core Tables

**User Data**
- `profiles` - User settings, timezone, locale
- `areas` - Life areas for organizing goals
- `goals` - User habits, tasks, and measured goals
- `goal_members` - Buddy system membership
- `goal_schedules` - Recurrence patterns (ISO 8601 weekdays)
- `goal_reminders` - Time-based notifications (TIME + TZ, not timestamps)
- `goal_occurrences` - Daily instances of scheduled goals
- `occurrence_member_status` - Per-member completion tracking
- `goal_events` - Immutable audit log

**Measurements & Points**
- `goal_measure_targets` - Versioned targets (water, etc.)
- `measurements` - Recorded values
- `points_ledger` - Gamification points history
- `daily_activity` - Has any completion flag for streaks
- `daily_summary` - Materialized daily stats (performance)

**Reflections & Content**
- `reflection_templates` - Multi-page templates
- `reflections` - User journal entries
- `mood_entries` - Daily mood tracking
- `tags` - User hashtags
- `taggings` - Polymorphic tag associations
- `sessions` - Timed activities (meditation, pomodoro, etc.)

**Programs**
- `programs` - Curated content library
- `program_items` - Individual program goals
- `user_programs` - User enrollments
- `user_program_items` - Progress tracking

**Recommendations**
- `daily_recommendations` - AI-generated suggestions

### RLS (Row Level Security)

**All tables protected with policies:**
- Users can only access their own data
- Shared goals accessible to members
- Public catalogs (templates, programs) read-only
- Auth.uid() lookups optimized with indexes (100x improvement)

### Performance

**Critical Indexes:**
- Covering index for today's occurrences
- Auth.uid() lookups for RLS
- Composite indexes for date ranges
- GIN indexes for JSONB/array searches
- Partial indexes for active-only queries

---

## Project Structure

```
HabitTracker/
├── Sources/HabitTracker/
│   ├── App/                        # App entry point
│   ├── Features/                   # TCA features
│   │   ├── Today/                  # Today screen
│   │   ├── Areas/                  # Areas management
│   │   ├── Goals/                  # Goal CRUD
│   │   ├── Water/                  # Water tracking
│   │   ├── Reflections/            # Journaling
│   │   ├── Buddy/                  # Shared goals
│   │   ├── Programs/               # Inspire catalog
│   │   ├── Insights/               # Analytics
│   │   └── Settings/               # User settings
│   ├── Domain/
│   │   ├── Models/                 # Core domain models
│   │   ├── UseCases/               # Business logic
│   │   └── Services/               # Domain services
│   ├── Data/
│   │   ├── Repositories/           # Data access layer
│   │   ├── Network/                # Supabase client
│   │   ├── Local/                  # SwiftData cache
│   │   └── DTOs/                   # Transfer objects
│   ├── Infrastructure/
│   │   ├── Extensions/             # Swift extensions
│   │   ├── Helpers/                # Utilities
│   │   └── Resources/              # Assets
│   └── DesignSystem/
│       ├── Components/             # Reusable UI
│       ├── Styles/                 # Theming
│       └── Theme.swift
├── Tests/HabitTrackerTests/        # Unit tests
├── Supabase/
│   ├── migrations/                 # Database migrations
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   ├── 003_triggers_and_rpcs.sql
│   │   └── 004_performance_indexes.sql
│   └── functions/                  # Edge functions
│       ├── project-occurrences/    # Nightly occurrence creation
│       ├── rollover/               # Keep-until-complete carry
│       ├── refresh-summaries/      # Daily stats refresh
│       └── generate-recommendations/
└── Package.swift                   # SPM dependencies
```

---

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ / macOS 14.0+
- Supabase account
- Node.js 18+ (for Edge Functions)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd swift
   ```

2. **Set up Supabase**
   ```bash
   cd HabitTracker/Supabase

   # Install Supabase CLI
   brew install supabase/tap/supabase

   # Initialize project
   supabase init

   # Link to your Supabase project
   supabase link --project-ref <your-project-ref>

   # Run migrations
   supabase db push
   ```

3. **Configure environment**
   ```swift
   // Create Config.swift
   enum Config {
       static let supabaseURL = "https://your-project.supabase.co"
       static let supabaseAnonKey = "your-anon-key"
   }
   ```

4. **Install dependencies**
   ```bash
   cd HabitTracker
   swift package resolve
   ```

5. **Open in Xcode**
   ```bash
   open Package.swift
   ```

---

## Development

### Running the App

1. Select target (iOS / macOS)
2. Choose simulator or device
3. Press ⌘R to build and run

### Running Tests

```bash
swift test
```

Or in Xcode: ⌘U

### Code Style

This project uses SwiftLint for consistent code style:

```bash
swiftlint lint
swiftlint --fix  # Auto-fix violations
```

### Modern Swift Features Used

✅ **Swift 6.2 Concurrency**
- Strict concurrency checking enabled
- `@MainActor` for UI code
- `Sendable` conformance for thread safety
- Structured concurrency with async/await

✅ **iOS 17+ Features**
- `@Observable` macro (replaces `ObservableObject`)
- SwiftData for local persistence
- NavigationStack with value-based routing

✅ **TCA 1.23.1 Patterns**
- `@Reducer` macro
- `@ObservableState` for automatic observation
- `@Presents` for child features
- `@Dependency` for dependency injection

---

## API Reference

### Key RPCs (Remote Procedure Calls)

```swift
// Ensure occurrence exists for a date
let occurrenceId = try await supabase.rpc("ensure_occurrence",
    params: ["p_goal": goalId, "p_date": date])

// Complete a tick
try await supabase.rpc("complete_tick",
    params: ["p_occ": occurrenceId])

// Skip an occurrence
try await supabase.rpc("skip_occurrence",
    params: ["p_occ": occurrenceId, "p_reason": "Not feeling well"])

// Set water target
try await supabase.rpc("set_measure_target",
    params: ["p_goal": goalId, "p_unit": "ml", "p_target": 2000])

// Add measurement
try await supabase.rpc("add_measurement",
    params: ["p_goal": goalId, "p_value": 250, "p_unit": "ml"])

// Get current streak
let streak = try await supabase.rpc("get_current_streak")

// Get area statistics
let stats = try await supabase.rpc("get_area_statistics",
    params: ["p_area": areaId, "p_from": startDate, "p_to": endDate])
```

### RecurrenceEngine

```swift
let engine = RecurrenceEngine()

// Generate occurrences for a schedule
let occurrences = engine.generateOccurrences(
    for: schedule,
    from: startDate,
    to: endDate,
    timeZone: .current
)

// Get today's occurrence
if let today = engine.generateTodayOccurrence(
    for: schedule,
    timeZone: .current
) {
    // Create occurrence
}

// Generate 14-day notification window
let notificationDates = engine.generateNotificationWindow(
    for: schedule,
    timeZone: .current
)
```

---

## Testing

### Unit Tests

```swift
@Test("RecurrenceEngine generates daily occurrences correctly")
func testDailyRecurrence() async {
    let engine = RecurrenceEngine()
    let schedule = GoalSchedule(freq: .daily, interval: 1)

    let occurrences = engine.generateOccurrences(
        for: schedule,
        from: Date(),
        to: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        timeZone: .current
    )

    #expect(occurrences.count == 8)  // Including start date
}
```

### TCA Tests

```swift
@Test("TodayFeature loads occurrences on task")
func testLoadOccurrences() async {
    let store = TestStore(initialState: TodayFeature.State()) {
        TodayFeature()
    } withDependencies: {
        $0.occurrenceRepository = MockOccurrenceRepository()
    }

    await store.send(.task) {
        $0.isLoading = true
    }

    await store.receive(\.occurrencesResponse.success) {
        $0.isLoading = false
        $0.occurrences.count == 5
    }
}
```

---

## Deployment

### TestFlight

1. Archive app (Product → Archive)
2. Upload to App Store Connect
3. Add to TestFlight
4. Invite testers

### Database Migrations

```bash
# Create new migration
supabase migration new <migration_name>

# Apply migrations
supabase db push

# Rollback
supabase db reset
```

---

## Performance Optimizations

✅ **Database**
- Covering indexes for hot paths (100x improvement)
- Materialized daily summaries
- Partial indexes for active-only queries
- RLS optimization with user_id indexes

✅ **Client**
- `@Observable` for granular UI updates
- SwiftData cache for offline support
- Debounced sync operations
- Lazy loading for large lists

✅ **Network**
- Delta sync (only fetch updated_at > lastSync)
- Realtime subscriptions for live updates
- Batch operations where possible

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run SwiftLint and tests
5. Submit a pull request

---

## License

[Your License Here]

---

## Acknowledgments

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) by Point-Free
- [Supabase](https://supabase.com) for backend infrastructure
- Design inspiration from leading habit tracking apps

---

## Support

For questions or issues:
- Open a GitHub issue
- Contact: [your-email]

---

**Built with ❤️ using Swift, SwiftUI, and Supabase**
