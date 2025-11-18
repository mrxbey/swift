# HabitTracker - Comprehensive Feature Design Specifications

**Created:** 2025-11-18
**Branch:** `claude/swiftui-app-planning-01Fxme8XNSYDtz7acgPdxC8i`
**Status:** Design Complete - Ready for Implementation

---

## Table of Contents

1. [Feature 1: Goals Management (Complete CRUD)](#feature-1-goals-management)
2. [Feature 2: Water Tracking](#feature-2-water-tracking)
3. [Feature 3: Buddy System](#feature-3-buddy-system)
4. [Feature 4: Reflections](#feature-4-reflections)
5. [Implementation Priority Matrix](#implementation-priority-matrix)
6. [Cross-Feature Dependencies](#cross-feature-dependencies)

---

# Feature 1: Goals Management (Complete CRUD)

## Overview

**Current State:** Backend complete, editor view is placeholder
**Goal:** Complete, user-friendly goal creation and editing experience
**Priority:** P0 - BLOCKING (app unusable without this)
**Estimated Effort:** 5-7 days

## User Stories

### Primary Stories
1. As a user, I want to **create a new habit in <60 seconds** so I can quickly start tracking
2. As a user, I want to **choose from templates** so I don't have to configure everything manually
3. As a user, I want to **customize my goal** (name, emoji, schedule, points) so it fits my lifestyle
4. As a user, I want to **edit existing goals** so I can adapt to changing routines
5. As a user, I want to **pause/resume goals** so I don't lose streak data when taking breaks
6. As a user, I want to **delete goals with confirmation** to prevent accidental data loss

### Secondary Stories
7. As a user, I want to **duplicate goals** to quickly create similar habits
8. As a user, I want to **set advanced schedules** (monthly, custom days) for complex routines
9. As a user, I want to **set flexible counts** (1-10 times per day) for multi-session habits
10. As a user, I want to **link to exercises** for specific workout tracking

## UI/UX Design

### Entry Points

**From Today View:**
- Primary: `+` button in navigation bar → Goal Creation Sheet
- Secondary: Tap "Add goal" in empty state → Goal Creation Sheet

**From Areas:**
- Area Detail View → `+` button → Goal Creation Sheet (area pre-selected)

**From Goals List:**
- Tap existing goal row → Goal Detail View → Edit button → Goal Editor Sheet

### Goal Creation Flow (Simple Path)

**Step 1: Template Selection (NEW)**
```
┌─────────────────────────────────┐
│ Create New Goal                 │
│─────────────────────────────────│
│                                 │
│  Quick Start Templates          │
│  ┌─────────────────────────┐   │
│  │ 🧘 Morning Meditation   │   │
│  │ Daily • 10 min • 5pts   │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 💧 Drink Water          │   │
│  │ 8 times daily • 2pts    │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 🏃 Exercise             │   │
│  │ 3x per week • 10pts     │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ ➕ Custom Goal          │   │
│  └─────────────────────────┘   │
│                                 │
│ [Cancel]                        │
└─────────────────────────────────┘
```

**Step 2: Goal Form (Simplified)**
```
┌─────────────────────────────────┐
│ New Goal              [Cancel]  │
│─────────────────────────────────│
│                                 │
│  🧘  [Tap to change emoji]      │
│                                 │
│  Goal Name                      │
│  ┌─────────────────────────┐   │
│  │ Morning Meditation      │   │
│  └─────────────────────────┘   │
│                                 │
│  Area                           │
│  ┌─────────────────────────┐   │
│  │ 🧠 Mindfulness     >    │   │
│  └─────────────────────────┘   │
│                                 │
│  Frequency                      │
│  ┌───┐ ┌────┐ ┌──────┐         │
│  │ ✓ │ │    │ │      │         │
│  │Day│ │Week│ │Month │         │
│  └───┘ └────┘ └──────┘         │
│                                 │
│  Times per day: 1               │
│  ┌─────────────────────────┐   │
│  │ ● ○ ○ ○ ○ ○ ○ ○ ○ ○   │   │
│  └─────────────────────────┘   │
│  (Drag to change)               │
│                                 │
│  Points: 5                      │
│  ┌─────────────────────────┐   │
│  │ ─────●──────            │   │
│  │ 1    5    10            │   │
│  └─────────────────────────┘   │
│                                 │
│  ⌄ Advanced Options             │
│                                 │
│           [Save Goal]           │
│                                 │
└─────────────────────────────────┘
```

**Step 3: Advanced Options (Expandable)**
```
┌─────────────────────────────────┐
│  ⌄ Advanced Options             │
│─────────────────────────────────│
│                                 │
│  Specific Days (Weekly)         │
│  ┌───────────────────────────┐ │
│  │ M  T  W  T  F  S  S       │ │
│  │ ✓  ✓  ✓  ✓  ✓  ○  ○      │ │
│  └───────────────────────────┘ │
│                                 │
│  Keep Until Complete            │
│  ┌───────────────────────────┐ │
│  │ ○ Rollover to next day    │ │
│  │   if not completed        │ │
│  └───────────────────────────┘ │
│                                 │
│  Linked Exercise (Optional)    │
│  ┌───────────────────────────┐ │
│  │ None              >       │ │
│  └───────────────────────────┘ │
│                                 │
│  Hashtags                       │
│  ┌───────────────────────────┐ │
│  │ #health #morning          │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

### Goal Editor (Edit Existing)

**Same form as creation, but:**
- Pre-filled with existing values
- "Delete Goal" button at bottom (destructive style)
- "Pause Goal" toggle at top
- Shows "Created: X days ago" metadata
- Shows "Current Streak: X days" (read-only)

### Goal Detail View (NEW)

```
┌─────────────────────────────────┐
│ < Goals   🧘 Morning Meditation │
│─────────────────────────────────│
│                                 │
│  ┌─────────────────────────┐   │
│  │    Current Streak       │   │
│  │         14 🔥           │   │
│  │                         │   │
│  │    Longest: 21 days     │   │
│  └─────────────────────────┘   │
│                                 │
│  Details                        │
│  ┌─────────────────────────┐   │
│  │ Area: 🧠 Mindfulness    │   │
│  │ Frequency: Daily        │   │
│  │ Times/day: 1            │   │
│  │ Points: 5               │   │
│  │ Created: 14 days ago    │   │
│  └─────────────────────────┘   │
│                                 │
│  This Week                      │
│  ┌─────────────────────────┐   │
│  │ M  T  W  T  F  S  S     │   │
│  │ ✓  ✓  ✓  ✓  ✓  ✓  ○    │   │
│  │ Completion: 86%         │   │
│  └─────────────────────────┘   │
│                                 │
│  Recent Activity                │
│  ┌─────────────────────────┐   │
│  │ ✓ Today, 8:30 AM        │   │
│  │ ✓ Yesterday, 8:45 AM    │   │
│  │ ✓ Dec 15, 9:00 AM       │   │
│  └─────────────────────────┘   │
│                                 │
│         [Edit Goal]             │
│                                 │
└─────────────────────────────────┘
```

## TCA Architecture

### New Feature: `GoalFormFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    // Form fields
    var name: String = ""
    var emoji: String = "🎯"
    var areaId: UUID?
    var kind: GoalKind = .habit
    var frequency: PeriodFrequency = .daily
    var timesPerDay: Int = 1
    var pointsPerCompletion: Int = 5
    var keepUntilComplete: Bool = false
    var linkedExercise: LinkedExercise? = nil
    var hashtags: [String] = []

    // Schedule (if weekly/monthly)
    var selectedWeekdays: Set<Int> = []
    var selectedMonthdays: Set<Int> = []

    // UI state
    var isLoading: Bool = false
    var showingEmojiPicker: Bool = false
    var showingAreaPicker: Bool = false
    var showingExercisePicker: Bool = false
    var showAdvancedOptions: Bool = false
    var errorMessage: String? = nil

    // Template selection
    var selectedTemplate: GoalTemplate? = nil

    // Edit mode
    var editingGoal: Goal? = nil
    var isEditing: Bool { editingGoal != nil }

    // Validation
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        areaId != nil
    }
}
```

**Actions:**
```swift
public enum Action: Sendable {
    // Form updates
    case nameChanged(String)
    case emojiTapped
    case emojiSelected(String)
    case areaTapped
    case areaSelected(UUID)
    case kindChanged(GoalKind)
    case frequencyChanged(PeriodFrequency)
    case timesPerDayChanged(Int)
    case pointsChanged(Int)
    case keepUntilCompleteToggled
    case linkedExerciseTapped
    case linkedExerciseSelected(LinkedExercise?)
    case hashtagsChanged(String)
    case weekdayToggled(Int)
    case monthdayToggled(Int)
    case advancedOptionsToggled

    // Template selection
    case templateSelected(GoalTemplate)

    // Save/Cancel
    case saveButtonTapped
    case cancelButtonTapped
    case deleteButtonTapped
    case confirmDeleteTapped

    // Async responses
    case saveResponse(Result<Goal, Error>)
    case deleteResponse(Result<Void, Error>)

    // Child actions
    case emojiPicker(PresentationAction<EmojiPickerFeature.Action>)
    case areaPicker(PresentationAction<AreaPickerFeature.Action>)

    // Delegate
    case delegate(Delegate)

    public enum Delegate: Sendable {
        case goalSaved(Goal)
        case goalDeleted(UUID)
        case cancelled
    }
}
```

**Dependencies:**
```swift
@Dependency(\.goalRepository) var goalRepository
@Dependency(\.areaRepository) var areaRepository
@Dependency(\.dismiss) var dismiss
@Dependency(\.haptics) var haptics
```

**Reducer Logic:**
```swift
public var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case let .templateSelected(template):
            state.name = template.name
            state.emoji = template.emoji
            state.frequency = template.frequency
            state.timesPerDay = template.timesPerDay
            state.pointsPerCompletion = template.points
            state.selectedTemplate = template
            return .none

        case .saveButtonTapped:
            guard state.canSave else { return .none }
            state.isLoading = true

            let goal: Goal
            if let editing = state.editingGoal {
                // Update existing goal
                goal = Goal(
                    id: editing.id,
                    userId: editing.userId,
                    areaId: state.areaId!,
                    title: state.name,
                    emoji: state.emoji,
                    kind: state.kind,
                    status: editing.status,
                    keepUntilComplete: state.keepUntilComplete,
                    timesPerDay: state.timesPerDay,
                    pointsPerCompletion: state.pointsPerCompletion,
                    linkedExerciseKey: state.linkedExercise,
                    hashtags: state.hashtags,
                    createdAt: editing.createdAt,
                    updatedAt: Date()
                )
            } else {
                // Create new goal
                goal = Goal(
                    id: UUID(),
                    userId: UUID(), // TODO: Get from auth
                    areaId: state.areaId!,
                    title: state.name,
                    emoji: state.emoji,
                    kind: state.kind,
                    status: .active,
                    keepUntilComplete: state.keepUntilComplete,
                    timesPerDay: state.timesPerDay,
                    pointsPerCompletion: state.pointsPerCompletion,
                    linkedExerciseKey: state.linkedExercise,
                    hashtags: state.hashtags
                )
            }

            return .run { send in
                await send(.saveResponse(
                    Result {
                        if state.isEditing {
                            try await goalRepository.update(goal)
                        } else {
                            try await goalRepository.create(goal)
                        }
                        return goal
                    }
                ))
            }

        case let .saveResponse(.success(goal)):
            state.isLoading = false
            return .run { send in
                await haptics.success()
                await send(.delegate(.goalSaved(goal)))
                await dismiss()
            }

        case let .saveResponse(.failure(error)):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            return .run { _ in await haptics.error() }

        // ... other cases

        default:
            return .none
        }
    }
    .ifLet(\.$emojiPicker, action: \.emojiPicker) {
        EmojiPickerFeature()
    }
    .ifLet(\.$areaPicker, action: \.areaPicker) {
        AreaPickerFeature()
    }
}
```

### Goal Templates

**New Model:**
```swift
public struct GoalTemplate: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let emoji: String
    public let category: TemplateCategory
    public let frequency: PeriodFrequency
    public let timesPerDay: Int
    public let points: Int
    public let linkedExercise: LinkedExercise?

    public enum TemplateCategory: String {
        case health, productivity, mindfulness, social, learning
    }

    public static let popular: [GoalTemplate] = [
        GoalTemplate(
            id: "morning-meditation",
            name: "Morning Meditation",
            emoji: "🧘",
            category: .mindfulness,
            frequency: .daily,
            timesPerDay: 1,
            points: 5,
            linkedExercise: nil
        ),
        GoalTemplate(
            id: "drink-water",
            name: "Drink Water",
            emoji: "💧",
            category: .health,
            frequency: .daily,
            timesPerDay: 8,
            points: 2,
            linkedExercise: nil
        ),
        GoalTemplate(
            id: "exercise",
            name: "Exercise",
            emoji: "🏃",
            category: .health,
            frequency: .weekly,
            timesPerDay: 1,
            points: 10,
            linkedExercise: .running
        ),
        // ... more templates
    ]
}
```

## Implementation Plan

### Phase 1: Template Selection (Day 1)
- [ ] Create `GoalTemplate` model
- [ ] Design template selection view
- [ ] Implement template data source
- [ ] Wire up template selection to form

### Phase 2: Simple Goal Form (Days 2-3)
- [ ] Implement `GoalFormFeature` (basic fields)
- [ ] Create `GoalFormView` SwiftUI view
- [ ] Emoji picker integration
- [ ] Area picker integration
- [ ] Frequency selector (Daily/Weekly/Monthly)
- [ ] Times-per-day slider/picker
- [ ] Points slider
- [ ] Form validation

### Phase 3: Advanced Options (Day 4)
- [ ] Weekday selector (for weekly goals)
- [ ] Month day selector (for monthly goals)
- [ ] Keep-until-complete toggle
- [ ] Linked exercise picker
- [ ] Hashtag input
- [ ] Collapsible advanced section

### Phase 4: Save Logic (Day 5)
- [ ] Wire up goal repository
- [ ] Create goal (new)
- [ ] Update goal (edit)
- [ ] Handle async responses
- [ ] Error handling
- [ ] Success feedback (haptics, dismiss)

### Phase 5: Goal Detail View (Day 6)
- [ ] Create `GoalDetailFeature`
- [ ] Display goal information
- [ ] Show streak data
- [ ] Show recent completions
- [ ] "Edit" button navigation

### Phase 6: Edit & Delete (Day 7)
- [ ] Load existing goal into form
- [ ] Update flow
- [ ] Delete confirmation alert
- [ ] Delete with repository
- [ ] Pause/resume toggle

## Acceptance Criteria

### Must Have
- [ ] User can create a goal in <60 seconds
- [ ] User can select from 10+ templates
- [ ] User can customize all goal properties
- [ ] User can edit existing goals
- [ ] User can delete goals with confirmation
- [ ] Form validates required fields
- [ ] Success/error feedback provided
- [ ] Changes sync to Supabase
- [ ] Offline changes queued

### Should Have
- [ ] User can duplicate goals
- [ ] User can pause/resume goals
- [ ] Advanced options are optional (collapsed by default)
- [ ] Emoji picker is native and fast
- [ ] Area picker shows existing areas

### Nice to Have
- [ ] Smart suggestions based on existing goals
- [ ] Import from Programs
- [ ] Batch create (multiple goals at once)

## Testing Checklist

### Unit Tests
- [ ] Goal creation with valid data succeeds
- [ ] Goal creation with invalid data fails
- [ ] Goal update modifies existing goal
- [ ] Goal deletion removes goal
- [ ] Template selection pre-fills form
- [ ] Form validation works correctly
- [ ] Weekday selection for weekly goals
- [ ] Monthday selection for monthly goals

### Integration Tests
- [ ] Create goal → appears in Today view
- [ ] Edit goal → changes reflect immediately
- [ ] Delete goal → removed from all views
- [ ] Offline create → syncs when online
- [ ] Template → create → complete occurrence flow

### UI Tests
- [ ] Goal form displays correctly
- [ ] Template selection navigates to form
- [ ] Save button creates goal and dismisses sheet
- [ ] Cancel button dismisses without saving
- [ ] Delete shows confirmation alert
- [ ] Error messages display correctly

---

# Feature 2: Water Tracking

## Overview

**Current State:** Backend complete (models, DTOs, repository), NO UI
**Goal:** Simple, delightful daily water tracking
**Priority:** P1 - HIGH (health-focused users need this)
**Estimated Effort:** 3-4 days

## User Stories

### Primary Stories
1. As a user, I want to **log water intake with one tap** so tracking is frictionless
2. As a user, I want to **see visual progress toward my daily goal** so I stay motivated
3. As a user, I want to **set a daily water target** (mL or oz) that fits my needs
4. As a user, I want to **quick-add common amounts** (250mL, 500mL, 1L) for speed

### Secondary Stories
5. As a user, I want to **view my water history** to understand patterns
6. As a user, I want to **undo mistaken entries** to fix errors
7. As a user, I want to **customize quick-add buttons** for my bottle sizes
8. As a user, I want to **get reminders to drink water** throughout the day

## UI/UX Design

### Today View Integration (Existing Widget Enhancement)

**Current Water Card (Enhanced):**
```
┌────────────────────────────────────┐
│ 💧 Water                           │
│────────────────────────────────────│
│                                    │
│    1,200 mL / 2,000 mL             │
│   ┌──────────────────────┐         │
│   │████████░░░░░░░░░░░░░░│ 60%    │
│   └──────────────────────┘         │
│                                    │
│   Quick Add:                       │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐     │
│   │+100│ │+250│ │+500│ │+1L │     │
│   └────┘ └────┘ └────┘ └────┘     │
│                                    │
│   [View Details >]                 │
└────────────────────────────────────┘
```

**Tap Behavior:**
- Quick-add buttons → Instant add with haptic + animation
- "View Details" → Navigate to Water Detail View (new)

### Water Detail View (NEW)

```
┌─────────────────────────────────┐
│ < Today    💧 Water Intake      │
│─────────────────────────────────│
│                                 │
│  Today's Progress               │
│  ┌─────────────────────────┐   │
│  │    1,200 mL / 2,000 mL  │   │
│  │   ┌──────────────────┐  │   │
│  │   │████████░░░░░░░░░░│  │   │
│  │   └──────────────────┘  │   │
│  │        60% Complete     │   │
│  │                         │   │
│  │  🎯 Goal: 800 mL left  │   │
│  └─────────────────────────┘   │
│                                 │
│  Quick Add                      │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │+100│ │+250│ │+500│          │
│  │ mL │ │ mL │ │ mL │          │
│  └────┘ └────┘ └────┘          │
│  ┌────┐ ┌────┐ ┌─────────┐    │
│  │+1L │ │+2L │ │ Custom  │    │
│  │    │ │    │ │ Amount  │    │
│  └────┘ └────┘ └─────────┘    │
│                                 │
│  Today's Log                    │
│  ┌─────────────────────────┐   │
│  │ 500 mL  •  3:45 PM  [X] │   │
│  │ 250 mL  •  1:20 PM  [X] │   │
│  │ 250 mL  • 11:00 AM  [X] │   │
│  │ 200 mL  •  8:30 AM  [X] │   │
│  └─────────────────────────┘   │
│                                 │
│  This Week                      │
│  ┌─────────────────────────┐   │
│  │ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐     │   │
│  │ │█│ │█│ │█│ │▓│ │░│     │   │
│  │ │█│ │█│ │█│ │▓│ │░│     │   │
│  │ │█│ │▓│ │▓│ │░│ │░│     │   │
│  │ └─┘ └─┘ └─┘ └─┘ └─┘     │   │
│  │  M   T   W   T   F       │   │
│  │                           │   │
│  │ Avg: 1,800 mL/day        │   │
│  └─────────────────────────┘   │
│                                 │
│         [Settings]              │
│                                 │
└─────────────────────────────────┘
```

### Water Settings Sheet

```
┌─────────────────────────────────┐
│ Water Settings       [Cancel]   │
│─────────────────────────────────│
│                                 │
│  Daily Target                   │
│  ┌─────────────────────────┐   │
│  │ ─────●──────            │   │
│  │ 1L   2L   3L            │   │
│  └─────────────────────────┘   │
│  Currently: 2,000 mL            │
│                                 │
│  Units                          │
│  ┌────┐ ┌────┐                 │
│  │ ✓  │ │    │                 │
│  │ mL │ │ oz │                 │
│  └────┘ └────┘                 │
│                                 │
│  Quick Add Buttons              │
│  ┌─────────────────────────┐   │
│  │ Button 1:  [250 mL  >]  │   │
│  │ Button 2:  [500 mL  >]  │   │
│  │ Button 3:  [1000 mL >]  │   │
│  │ Button 4:  [2000 mL >]  │   │
│  └─────────────────────────┘   │
│                                 │
│  Reminders                      │
│  ┌─────────────────────────┐   │
│  │ ○ Remind me to drink    │   │
│  │   Every: 2 hours        │   │
│  │   Between: 8 AM - 8 PM  │   │
│  └─────────────────────────┘   │
│                                 │
│           [Save]                │
│                                 │
└─────────────────────────────────┘
```

### Custom Amount Entry

**Appears as alert/sheet when "Custom Amount" tapped:**
```
┌─────────────────────────────────┐
│ Add Water                       │
│─────────────────────────────────│
│                                 │
│  Amount                         │
│  ┌─────────────────────────┐   │
│  │ 350                     │   │
│  └─────────────────────────┘   │
│  mL                             │
│                                 │
│  When?                          │
│  ┌────────────────────────┐    │
│  │ ○ Now                  │    │
│  │ ● Earlier today        │    │
│  │   [3:30 PM        >]   │    │
│  └────────────────────────┘    │
│                                 │
│  [Cancel]        [Add]          │
│                                 │
└─────────────────────────────────┘
```

## TCA Architecture

### Feature: `WaterTrackingFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    // Target
    var dailyTargetML: Int = 2000 // Default 2L
    var preferredUnit: Unit = .milliliters

    // Today's progress
    var todaysMeasurements: IdentifiedArrayOf<Measurement> = []
    var totalIntakeToday: Int = 0
    var progress: Double = 0.0

    // This week
    var weeklyData: [DayWaterData] = []

    // UI state
    var isLoading: Bool = false
    var showingSettings: Bool = false
    var showingCustomEntry: Bool = false
    var errorMessage: String? = nil

    // Quick add buttons (customizable)
    var quickAddButtons: [Int] = [100, 250, 500, 1000, 2000]

    // Custom entry
    var customAmount: String = ""
    var customTime: Date = Date()
    var customIsNow: Bool = true

    public enum Unit: String, Codable {
        case milliliters, fluidOunces

        var abbreviation: String {
            switch self {
            case .milliliters: return "mL"
            case .fluidOunces: return "oz"
            }
        }
    }
}

public struct DayWaterData: Equatable, Identifiable {
    public let id: Date
    public let date: Date
    public let totalML: Int
    public let targetML: Int
    public var percentage: Double {
        Double(totalML) / Double(targetML)
    }
}
```

**Actions:**
```swift
public enum Action: Sendable {
    // Data loading
    case onAppear
    case refreshData
    case measurementsResponse(Result<[Measurement], Error>)

    // Quick add
    case quickAddTapped(Int) // Amount in mL
    case quickAddResponse(Result<Measurement, Error>)

    // Custom entry
    case customAmountTapped
    case customAmountChanged(String)
    case customTimeChanged(Date)
    case customIsNowToggled
    case addCustomTapped
    case cancelCustomTapped

    // Delete measurement
    case deleteMeasurement(UUID)
    case deleteResponse(Result<Void, Error>)

    // Settings
    case settingsTapped
    case settingsChanged(WaterSettings)
    case saveSettings

    // Child actions
    case settings(PresentationAction<WaterSettingsFeature.Action>)

    // Internal
    case calculateProgress
}
```

**Dependencies:**
```swift
@Dependency(\.measurementRepository) var measurementRepository
@Dependency(\.date.now) var now
@Dependency(\.calendar) var calendar
@Dependency(\.haptics) var haptics
@Dependency(\.userDefaults) var userDefaults
```

**Reducer Logic:**
```swift
public var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .onAppear:
            state.isLoading = true
            return .run { [userId = state.userId] send in
                await send(.refreshData)
            }

        case .refreshData:
            return .run { [userId = state.userId, now = now] send in
                await send(.measurementsResponse(
                    Result {
                        let today = calendar.startOfDay(for: now)
                        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

                        // Fetch today's water measurements
                        let measurements = try await measurementRepository.fetchMeasurements(
                            userId: userId,
                            from: today,
                            to: tomorrow,
                            unit: .milliliters
                        )
                        return measurements
                    }
                ))
            }

        case let .measurementsResponse(.success(measurements)):
            state.isLoading = false
            state.todaysMeasurements = IdentifiedArray(uniqueElements: measurements)
            return .send(.calculateProgress)

        case let .quickAddTapped(amount):
            return .run { [userId = state.userId, now = now] send in
                await haptics.impact(.medium)
                await send(.quickAddResponse(
                    Result {
                        let measurement = Measurement(
                            id: UUID(),
                            userId: userId,
                            goalId: nil, // Water is standalone
                            occurrenceId: nil,
                            value: Double(amount),
                            unit: .milliliters,
                            recordedAt: now
                        )
                        try await measurementRepository.create(measurement)
                        return measurement
                    }
                ))
            }

        case let .quickAddResponse(.success(measurement)):
            state.todaysMeasurements.append(measurement)
            return .concatenate(
                .send(.calculateProgress),
                .run { _ in
                    await haptics.success()
                }
            )

        case .calculateProgress:
            let total = state.todaysMeasurements.reduce(0) { $0 + Int($1.value) }
            state.totalIntakeToday = total
            state.progress = Double(total) / Double(state.dailyTargetML)
            return .none

        case let .deleteMeasurement(id):
            return .run { send in
                await send(.deleteResponse(
                    Result {
                        try await measurementRepository.delete(id)
                    }
                ))
            }

        case let .deleteResponse(.success):
            state.todaysMeasurements.removeAll { $0.id == id }
            return .send(.calculateProgress)

        // ... other cases

        default:
            return .none
        }
    }
    .ifLet(\.$settings, action: \.settings) {
        WaterSettingsFeature()
    }
}
```

### Feature: `WaterSettingsFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    var dailyTargetML: Int = 2000
    var preferredUnit: WaterTrackingFeature.State.Unit = .milliliters
    var quickAddButtons: [Int] = [100, 250, 500, 1000, 2000]
    var remindersEnabled: Bool = false
    var reminderIntervalHours: Int = 2
    var reminderStartTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    var reminderEndTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
}
```

## Implementation Plan

### Phase 1: Enhanced Today Widget (Day 1)
- [ ] Update existing water card in Today view
- [ ] Add quick-add button functionality
- [ ] Wire up to measurement repository
- [ ] Add progress animation
- [ ] Haptic feedback on add

### Phase 2: Water Detail View (Day 2)
- [ ] Create `WaterTrackingFeature`
- [ ] Implement WaterDetailView
- [ ] Display today's measurements list
- [ ] Delete measurement functionality
- [ ] Weekly bar chart visualization

### Phase 3: Custom Entry (Day 3)
- [ ] Custom amount input sheet
- [ ] Time picker (now vs. earlier)
- [ ] Validation (amount > 0)
- [ ] Save custom measurement

### Phase 4: Settings (Day 4)
- [ ] Create `WaterSettingsFeature`
- [ ] Daily target slider
- [ ] Unit toggle (mL/oz)
- [ ] Quick-add button customization
- [ ] Reminder configuration
- [ ] Persist to UserDefaults

## Acceptance Criteria

### Must Have
- [ ] User can add water with one tap from Today view
- [ ] Progress bar updates immediately
- [ ] User can view detailed water log
- [ ] User can delete mistaken entries
- [ ] User can set daily target
- [ ] Changes sync to Supabase

### Should Have
- [ ] Custom amount entry
- [ ] Weekly trend visualization
- [ ] Customizable quick-add buttons
- [ ] Haptic feedback on actions

### Nice to Have
- [ ] Reminders to drink water
- [ ] Achievement badges (7-day streak)
- [ ] Export water data

## Testing Checklist

### Unit Tests
- [ ] Add measurement increases total
- [ ] Delete measurement decreases total
- [ ] Progress calculation correct
- [ ] Unit conversion works (mL <-> oz)
- [ ] Target validation (> 0)

### Integration Tests
- [ ] Add water → syncs to Supabase
- [ ] Offline add → queues for sync
- [ ] Delete → removes from database
- [ ] Settings persist → reload correctly

### UI Tests
- [ ] Quick-add buttons work
- [ ] Progress bar animates
- [ ] Custom entry validates input
- [ ] Delete confirmation shown

---

# Feature 3: Buddy System

## Overview

**Current State:** Database complete, NO Swift code
**Goal:** Social accountability through shared goals
**Priority:** P2 - MEDIUM (differentiator feature)
**Estimated Effort:** 7-10 days

## User Stories

### Primary Stories
1. As a user, I want to **invite friends to share a goal** so we can motivate each other
2. As a user, I want to **see my buddy's progress on shared goals** to stay accountable
3. As a user, I want to **complete my portion of a shared goal** without affecting my buddy
4. As a user, I want to **be notified when my buddy completes their goal** for celebration

### Secondary Stories
5. As a user, I want to **create buddy-only goals** that don't appear in my solo goals
6. As a user, I want to **leave a shared goal** if I no longer want to participate
7. As a user, I want to **send encouragement messages** to buddies on shared goals
8. As a user, I want to **compare streaks** with my buddy for friendly competition

## UI/UX Design

### Entry Points

**From Goal Detail:**
- "Share Goal" button → Buddy Invite Sheet

**From Settings:**
- "Buddy System" → Buddy List View

**From Today View:**
- Shared goal badges (👥 icon)

### Buddy Invite Flow

**Step 1: Share Goal Sheet**
```
┌─────────────────────────────────┐
│ Share Goal           [Cancel]   │
│─────────────────────────────────│
│                                 │
│  🧘 Morning Meditation          │
│  Daily • 1x per day • 5 pts     │
│                                 │
│  Share with:                    │
│  ┌─────────────────────────┐   │
│  │ 🔍 Search friends...    │   │
│  └─────────────────────────┘   │
│                                 │
│  Your Buddies                   │
│  ┌─────────────────────────┐   │
│  │ ○ Sarah Johnson         │   │
│  │   @sarah • Active       │   │
│  ├─────────────────────────┤   │
│  │ ○ Mike Chen             │   │
│  │   @mike • Active        │   │
│  ├─────────────────────────┤   │
│  │ ○ Emma Davis            │   │
│  │   @emma • Inactive 2d   │   │
│  └─────────────────────────┘   │
│                                 │
│  [+ Invite by Email]            │
│                                 │
│         [Send Invite]           │
│                                 │
└─────────────────────────────────┘
```

**Step 2: Confirmation**
```
┌─────────────────────────────────┐
│ Invite Sent! ✓                  │
│─────────────────────────────────│
│                                 │
│  Sarah will be notified and     │
│  can accept your invitation.    │
│                                 │
│  Once accepted, you'll both     │
│  track this goal independently. │
│                                 │
│  The goal completes when BOTH   │
│  of you finish your daily       │
│  occurrences.                   │
│                                 │
│            [Got It]             │
│                                 │
└─────────────────────────────────┘
```

### Shared Goal View

**Today View (Enhanced for Shared Goals):**
```
┌────────────────────────────────────┐
│ 🧘 Morning Meditation      👥 [2]  │
│────────────────────────────────────│
│ Daily • 5 pts                      │
│                                    │
│ Your Progress:                     │
│ ┌────────────────┐                 │
│ │ [ Complete ] ✓ │ You're done!   │
│ └────────────────┘                 │
│                                    │
│ Buddy Progress:                    │
│ ┌────────────────────────────┐    │
│ │ Sarah    [●○○] 1/3        │    │
│ │ Mike     [✓✓✓] Complete ✓ │    │
│ └────────────────────────────┘    │
│                                    │
│ Goal completes when ALL members    │
│ finish their daily target.         │
│                                    │
│ [View Details >]                   │
└────────────────────────────────────┘
```

### Buddy Goal Detail View

```
┌─────────────────────────────────┐
│ < Back    🧘 Morning Meditation │
│─────────────────────────────────│
│                                 │
│  Shared with 2 buddies    👥    │
│                                 │
│  Team Streak                    │
│  ┌─────────────────────────┐   │
│  │         14 🔥           │   │
│  │                         │   │
│  │    Longest: 21 days     │   │
│  └─────────────────────────┘   │
│                                 │
│  Members                        │
│  ┌─────────────────────────┐   │
│  │ 👤 You              ✓   │   │
│  │    Streak: 14 days      │   │
│  │    Completed today      │   │
│  ├─────────────────────────┤   │
│  │ 👤 Sarah Johnson    ✓   │   │
│  │    Streak: 14 days      │   │
│  │    Completed today      │   │
│  ├─────────────────────────┤   │
│  │ 👤 Mike Chen         ○   │   │
│  │    Streak: 10 days      │   │
│  │    Not yet today        │   │
│  │    [Send Nudge 👋]      │   │
│  └─────────────────────────┘   │
│                                 │
│  This Week (Team)               │
│  ┌─────────────────────────┐   │
│  │ M  T  W  T  F  S  S     │   │
│  │ ✓  ✓  ✓  ✓  ✓  ✓  ○    │   │
│  │ Team: 86% complete      │   │
│  └─────────────────────────┘   │
│                                 │
│  [Edit Goal] [Leave Group]      │
│                                 │
└─────────────────────────────────┘
```

### Buddy List View (Settings → Buddies)

```
┌─────────────────────────────────┐
│ < Settings       Buddies        │
│─────────────────────────────────│
│                                 │
│  [+ Invite Friend]              │
│                                 │
│  Active Buddies                 │
│  ┌─────────────────────────┐   │
│  │ 👤 Sarah Johnson        │   │
│  │    @sarah               │   │
│  │    2 shared goals       │   │
│  │    Last active: now     │   │
│  ├─────────────────────────┤   │
│  │ 👤 Mike Chen            │   │
│  │    @mike                │   │
│  │    1 shared goal        │   │
│  │    Last active: 2h ago  │   │
│  └─────────────────────────┘   │
│                                 │
│  Pending Invites (1)            │
│  ┌─────────────────────────┐   │
│  │ 👤 Emma Davis           │   │
│  │    @emma                │   │
│  │    Invited 2 days ago   │   │
│  │    [Cancel Invite]      │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

## TCA Architecture

### New Models

**GoalMember (Domain Model):**
```swift
public struct GoalMember: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let goalId: UUID
    public let userId: UUID
    public let role: Role
    public let status: Status
    public let invitedAt: Date
    public let acceptedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date

    public enum Role: String, Codable {
        case owner, member
    }

    public enum Status: String, Codable {
        case pending, active, left
    }
}
```

**OccurrenceMemberStatus (Domain Model):**
```swift
public struct OccurrenceMemberStatus: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let occurrenceId: UUID
    public let memberId: UUID
    public let completedCount: Int
    public let targetCount: Int
    public let status: OccurrenceStatus
    public let completedAt: Date?

    public var isComplete: Bool {
        completedCount >= targetCount
    }
}
```

**BuddyProfile (View Model):**
```swift
public struct BuddyProfile: Identifiable, Equatable {
    public let id: UUID
    public let displayName: String
    public let username: String?
    public let avatarURL: URL?
    public let sharedGoalsCount: Int
    public let lastActiveAt: Date
    public let inviteStatus: GoalMember.Status
}
```

### Feature: `BuddySystemFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    var buddies: IdentifiedArrayOf<BuddyProfile> = []
    var pendingInvites: IdentifiedArrayOf<BuddyProfile> = []
    var isLoading: Bool = false
    var showingInviteSheet: Bool = false
    var errorMessage: String? = nil

    @Presents var inviteSheet: InviteBuddyFeature.State?
}
```

**Actions:**
```swift
public enum Action: Sendable {
    case onAppear
    case refreshBuddies
    case buddiesResponse(Result<[BuddyProfile], Error>)

    case inviteTapped
    case cancelInvite(UUID)
    case removeBuddy(UUID)

    case inviteSheet(PresentationAction<InviteBuddyFeature.Action>)
}
```

### Feature: `SharedGoalFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    var goal: Goal
    var members: IdentifiedArrayOf<GoalMember> = []
    var memberStatuses: [UUID: OccurrenceMemberStatus] = [:]
    var teamStreak: Int = 0
    var isLoading: Bool = false

    var allMembersComplete: Bool {
        members.allSatisfy { member in
            memberStatuses[member.id]?.isComplete ?? false
        }
    }
}
```

**Actions:**
```swift
public enum Action: Sendable {
    case onAppear
    case refreshMemberStatuses
    case memberStatusesResponse(Result<[OccurrenceMemberStatus], Error>)

    case sendNudge(UUID) // Send notification to buddy
    case leaveGoal
    case leaveConfirmed
}
```

## Implementation Plan

### Phase 1: Domain Models & DTOs (Days 1-2)
- [ ] Create GoalMember domain model
- [ ] Create OccurrenceMemberStatus domain model
- [ ] Create GoalMemberDTO
- [ ] Create OccurrenceMemberStatusDTO
- [ ] Create BuddyProfile view model

### Phase 2: Repositories (Days 3-4)
- [ ] Create SupabaseBuddyRepository
- [ ] Implement invite(goalId, userId)
- [ ] Implement accept(inviteId)
- [ ] Implement fetchBuddies(userId)
- [ ] Implement fetchMemberStatuses(occurrenceId)
- [ ] Implement updateMemberStatus(occurrenceId, memberId, status)
- [ ] Implement leaveGoal(goalId, userId)

### Phase 3: Buddy List UI (Day 5)
- [ ] Create BuddySystemFeature
- [ ] Create BuddyListView
- [ ] Display active buddies
- [ ] Display pending invites
- [ ] Implement cancel invite

### Phase 4: Invite Flow (Day 6)
- [ ] Create InviteBuddyFeature
- [ ] Create InviteBuddyView
- [ ] Search buddies
- [ ] Send invitations
- [ ] Accept/decline invitations

### Phase 5: Shared Goal UI (Days 7-8)
- [ ] Create SharedGoalFeature
- [ ] Enhance Today view for shared goals
- [ ] Create SharedGoalDetailView
- [ ] Display member statuses
- [ ] Team streak calculation

### Phase 6: Notifications (Days 9-10)
- [ ] Implement nudge/encouragement
- [ ] Push notifications for buddy completion
- [ ] Realtime updates using Supabase Realtime
- [ ] Badge counts for shared goal updates

## Acceptance Criteria

### Must Have
- [ ] User can invite friends to goals
- [ ] User can accept/decline invitations
- [ ] Shared goals show all member statuses
- [ ] Per-member completion tracking works
- [ ] User can complete their portion independently
- [ ] Team streak calculated correctly

### Should Have
- [ ] User receives notifications for buddy actions
- [ ] User can send nudges/encouragement
- [ ] User can leave shared goals
- [ ] Realtime status updates

### Nice to Have
- [ ] Leaderboards (who has most streaks)
- [ ] Buddy achievements
- [ ] Custom goal completion logic (AND vs. OR)

---

# Feature 4: Reflections

## Overview

**Current State:** Models exist, DTOs exist, NO UI
**Goal:** Daily journaling with multi-page templates
**Priority:** P2 - MEDIUM (engagement feature)
**Estimated Effort:** 4-5 days

## User Stories

### Primary Stories
1. As a user, I want to **write daily reflections** to process my thoughts and progress
2. As a user, I want to **use guided templates** (gratitude, wins, improvements) for structure
3. As a user, I want to **link reflections to goals** to track insights over time
4. As a user, I want to **view past reflections** to see my journey

### Secondary Stories
5. As a user, I want to **create custom templates** that fit my reflection style
6. As a user, I want to **set a daily reflection reminder** for consistency
7. As a user, I want to **export reflections** for backup or sharing
8. As a user, I want to **add photos** to reflections for context

## UI/UX Design

### Entry Points

**From Today View:**
- "Reflect on Today" card at bottom → Reflection Editor

**From Settings:**
- "Reflections" → Reflection History View

**From Insights:**
- "View Reflections" → Reflection History View

### Reflection Editor

```
┌─────────────────────────────────┐
│ Today's Reflection  [Cancel]    │
│─────────────────────────────────│
│                                 │
│  Template:                      │
│  ┌─────────────────────────┐   │
│  │ Daily Gratitude    >    │   │
│  └─────────────────────────┘   │
│                                 │
│  ● ○ ○ ○   Page 1 of 4         │
│                                 │
│  ┌─────────────────────────┐   │
│  │ What are you grateful   │   │
│  │ for today?              │   │
│  │                         │   │
│  │ [Tap to write...]       │   │
│  │                         │   │
│  │                         │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  Link to Goals (Optional)       │
│  ┌─────────────────────────┐   │
│  │ + Add related goals     │   │
│  └─────────────────────────┘   │
│                                 │
│  Mood (Optional)                │
│  ┌──────────────────────────┐  │
│  │ 😊 😐 😔 😡 😰 😴       │  │
│  └──────────────────────────┘  │
│                                 │
│  [Skip]   [Next Page >]         │
│                                 │
└─────────────────────────────────┘
```

**Page 2:**
```
┌─────────────────────────────────┐
│ Today's Reflection  [Cancel]    │
│─────────────────────────────────│
│                                 │
│  ○ ● ○ ○   Page 2 of 4         │
│                                 │
│  ┌─────────────────────────┐   │
│  │ What was your biggest   │   │
│  │ win today?              │   │
│  │                         │   │
│  │ [Completed morning      │   │
│  │  meditation despite     │   │
│  │  waking up late...]     │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [< Previous]  [Next Page >]    │
│                                 │
└─────────────────────────────────┘
```

**Final Page:**
```
┌─────────────────────────────────┐
│ Today's Reflection  [Cancel]    │
│─────────────────────────────────│
│                                 │
│  ○ ○ ○ ●   Page 4 of 4         │
│                                 │
│  ┌─────────────────────────┐   │
│  │ What will you improve   │   │
│  │ tomorrow?               │   │
│  │                         │   │
│  │ [Wake up earlier to     │   │
│  │  have more time for     │   │
│  │  meditation...]         │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  [< Previous]  [Save & Finish]  │
│                                 │
└─────────────────────────────────┘
```

### Reflection History

```
┌─────────────────────────────────┐
│ < Settings    Reflections       │
│─────────────────────────────────│
│                                 │
│  [+ New Reflection]             │
│                                 │
│  This Week                      │
│  ┌─────────────────────────┐   │
│  │ Today                   │   │
│  │ Daily Gratitude         │   │
│  │ "Grateful for morning   │   │
│  │  meditation and..."     │   │
│  │ 😊 • 4 pages            │   │
│  ├─────────────────────────┤   │
│  │ Yesterday               │   │
│  │ Daily Gratitude         │   │
│  │ "Completed all goals... │   │
│  │ 😊 • 4 pages            │   │
│  └─────────────────────────┘   │
│                                 │
│  Last Week                      │
│  ┌─────────────────────────┐   │
│  │ Dec 15                  │   │
│  │ Weekly Review           │   │
│  │ "Great progress this... │   │
│  │ 😊 • 6 pages            │   │
│  └─────────────────────────┘   │
│                                 │
│  Streaks & Stats                │
│  ┌─────────────────────────┐   │
│  │ Current Streak: 7 days  │   │
│  │ Total Reflections: 42   │   │
│  │ Most Used: Gratitude    │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Template Library

```
┌─────────────────────────────────┐
│ Choose Template     [Cancel]    │
│─────────────────────────────────│
│                                 │
│  Popular Templates              │
│  ┌─────────────────────────┐   │
│  │ 📝 Daily Gratitude      │   │
│  │    4 pages • 5 min      │   │
│  │    Used: 28 times       │   │
│  ├─────────────────────────┤   │
│  │ 🎯 Goal Reflection      │   │
│  │    3 pages • 5 min      │   │
│  │    Used: 12 times       │   │
│  ├─────────────────────────┤   │
│  │ 📊 Weekly Review        │   │
│  │    6 pages • 10 min     │   │
│  │    Used: 4 times        │   │
│  ├─────────────────────────┤   │
│  │ 🧠 Self-Compassion      │   │
│  │    5 pages • 8 min      │   │
│  │    Used: 0 times        │   │
│  └─────────────────────────┘   │
│                                 │
│  [+ Create Custom Template]     │
│                                 │
└─────────────────────────────────┘
```

## TCA Architecture

### Feature: `ReflectionEditorFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    var template: ReflectionTemplate
    var currentPage: Int = 0
    var pages: IdentifiedArrayOf<ReflectionPage> = []
    var linkedGoals: IdentifiedArrayOf<Goal> = []
    var mood: MoodType? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var canGoNext: Bool {
        currentPage < template.pages.count - 1
    }

    var canGoPrevious: Bool {
        currentPage > 0
    }

    var isLastPage: Bool {
        currentPage == template.pages.count - 1
    }
}

public struct ReflectionPage: Identifiable, Equatable {
    public let id: UUID
    public let prompt: String
    public let order: Int
    public var content: String = ""
}
```

**Actions:**
```swift
public enum Action: Sendable {
    case onAppear
    case templateSelected(ReflectionTemplate)

    case pageContentChanged(String)
    case nextPageTapped
    case previousPageTapped
    case skipPageTapped

    case moodSelected(MoodType?)
    case linkGoal(UUID)
    case unlinkGoal(UUID)

    case saveTapped
    case saveResponse(Result<Reflection, Error>)
    case cancelTapped
}
```

**Reducer Logic:**
```swift
public var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case let .templateSelected(template):
            state.template = template
            state.pages = IdentifiedArray(
                uniqueElements: template.pages.enumerated().map { index, prompt in
                    ReflectionPage(
                        id: UUID(),
                        prompt: prompt,
                        order: index,
                        content: ""
                    )
                }
            )
            return .none

        case let .pageContentChanged(content):
            state.pages[id: state.pages[state.currentPage].id]?.content = content
            return .none

        case .nextPageTapped:
            guard state.canGoNext else { return .none }
            state.currentPage += 1
            return .run { _ in await haptics.impact(.light) }

        case .previousPageTapped:
            guard state.canGoPrevious else { return .none }
            state.currentPage -= 1
            return .run { _ in await haptics.impact(.light) }

        case .saveTapped:
            state.isLoading = true

            let reflection = Reflection(
                id: UUID(),
                userId: UUID(), // TODO: Get from auth
                templateId: state.template.id,
                pages: state.pages.map { page in
                    Reflection.Page(
                        prompt: page.prompt,
                        content: page.content,
                        order: page.order
                    )
                },
                linkedGoalIds: state.linkedGoals.map(\.id),
                mood: state.mood,
                createdAt: Date()
            )

            return .run { send in
                await send(.saveResponse(
                    Result {
                        try await reflectionRepository.create(reflection)
                        return reflection
                    }
                ))
            }

        case let .saveResponse(.success):
            state.isLoading = false
            return .run { send in
                await haptics.success()
                await send(.delegate(.reflectionSaved))
                await dismiss()
            }

        // ... other cases

        default:
            return .none
        }
    }
}
```

### Feature: `ReflectionHistoryFeature`

**State:**
```swift
@ObservableState
public struct State: Equatable {
    var reflections: IdentifiedArrayOf<Reflection> = []
    var currentStreak: Int = 0
    var totalReflections: Int = 0
    var mostUsedTemplate: String? = nil
    var isLoading: Bool = false

    @Presents var editor: ReflectionEditorFeature.State?
}
```

## Implementation Plan

### Phase 1: Templates (Day 1)
- [ ] Load default templates from database
- [ ] Create template selection UI
- [ ] Template model integration

### Phase 2: Editor UI (Days 2-3)
- [ ] Create ReflectionEditorFeature
- [ ] Build multi-page form
- [ ] Navigation (previous/next)
- [ ] Text input handling
- [ ] Mood selector
- [ ] Goal linking

### Phase 3: Save Logic (Day 4)
- [ ] Create SupabaseReflectionRepository
- [ ] Implement save reflection
- [ ] Page content serialization
- [ ] Linked goals persistence

### Phase 4: History View (Day 5)
- [ ] Create ReflectionHistoryFeature
- [ ] Display list of reflections
- [ ] Streak calculation
- [ ] Stats display

## Acceptance Criteria

### Must Have
- [ ] User can create reflection from template
- [ ] User can navigate multi-page forms
- [ ] User can save reflections
- [ ] User can view past reflections
- [ ] Streak calculated correctly

### Should Have
- [ ] User can link reflections to goals
- [ ] User can log mood
- [ ] User can use default templates

### Nice to Have
- [ ] User can create custom templates
- [ ] User can export reflections
- [ ] User can add photos

---

# Implementation Priority Matrix

## Critical Path (MVP)

**Week 1-2: Goals Management** (BLOCKING)
- Without this, app is unusable
- Blocks: Everything

**Week 3: Water Tracking**
- High user value
- Simple implementation
- Differentiator

**Week 4-5: Buddy System**
- Core differentiator
- Complex but high value
- Requires Goals to be complete

**Week 6: Reflections**
- Engagement feature
- Can be post-MVP

## Dependency Graph

```
Goals Management (P0)
  ↓
Water Tracking (P1)
  ↓
Buddy System (P2) ← depends on Goals
  ↓
Reflections (P3) ← depends on Goals
```

## Effort vs. Impact

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| Goals Management | HIGH (7d) | CRITICAL | P0 |
| Water Tracking | LOW (4d) | HIGH | P1 |
| Buddy System | HIGH (10d) | MEDIUM | P2 |
| Reflections | MEDIUM (5d) | MEDIUM | P3 |

---

# Cross-Feature Dependencies

## Shared Components

### Emoji Picker
Used by: Goals, Areas (already implemented)

### Area Picker
Used by: Goals (needs implementation)

### Goal Picker
Used by: Reflections, Buddy System (NEW)

### Haptic Feedback Service
Used by: All features (implement once)

### Date Range Picker
Used by: Water, Reflections (NEW)

## Data Flow

```
User creates Goal
  → Goal appears in Today view
  → User completes occurrence
  → Progress updates in Insights
  → User can share Goal (Buddy System)
  → User can reflect on Goal (Reflections)
  → User tracks measurements (Water)
```

## Notifications

All features need:
- Daily reminders
- Streak alerts
- Buddy updates (Buddy System only)

**Recommendation:** Build centralized NotificationService first

---

**Document Version:** 1.0
**Last Updated:** 2025-11-18
**Status:** ✅ Design Complete - Ready for Implementation
**Next Step:** Create enterprise-grade task tracker from these designs
