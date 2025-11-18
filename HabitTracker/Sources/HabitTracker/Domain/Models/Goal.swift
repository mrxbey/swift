import Foundation

/// A user goal - can be a habit, one-time task, or measured goal (water)
@Observable
public final class Goal: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var userId: UUID
    public var areaId: UUID
    public var title: String
    public var emoji: String?
    public var kind: GoalKind
    public var status: GoalStatus
    public var keepUntilComplete: Bool
    public var timesPerDay: Int
    public var pointsPerCompletion: Int
    public var linkedExerciseKey: LinkedExercise?
    public var hashtags: [String]
    public let createdAt: Date
    public var updatedAt: Date

    /// MARK: - Lifecycle

    public init(
        id: UUID = UUID(),
        userId: UUID,
        areaId: UUID,
        title: String,
        emoji: String? = nil,
        kind: GoalKind = .habit,
        status: GoalStatus = .active,
        keepUntilComplete: Bool = false,
        timesPerDay: Int = 1,
        pointsPerCompletion: Int = 5,
        linkedExerciseKey: LinkedExercise? = nil,
        hashtags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.areaId = areaId
        self.title = title
        self.emoji = emoji
        self.kind = kind
        self.status = status
        self.keepUntilComplete = keepUntilComplete
        self.timesPerDay = min(max(timesPerDay, 1), 100) // Enforce 1-100 constraint
        self.pointsPerCompletion = max(pointsPerCompletion, 0)
        self.linkedExerciseKey = linkedExerciseKey
        self.hashtags = hashtags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// MARK: - Computed Properties

    public var displayName: String {
        if let emoji = emoji {
            return "\(emoji) \(title)"
        }
        return title
    }

    public var isRepeating: Bool {
        kind == .habit
    }

    public var isOneTime: Bool {
        kind == .task
    }

    public var isMeasured: Bool {
        kind == .measure
    }

    /// MARK: - Equatable

    public static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.emoji == rhs.emoji &&
        lhs.kind == rhs.kind &&
        lhs.status == rhs.status &&
        lhs.timesPerDay == rhs.timesPerDay
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - GoalKind

public enum GoalKind: String, Codable, Sendable, CaseIterable {
    case habit      // Repeating habit
    case task       // One-time task
    case measure    // Measured goal (water, steps, etc.)

    public var displayName: String {
        switch self {
        case .habit: return "Habit"
        case .task: return "Task"
        case .measure: return "Measure"
        }
    }

    public var icon: String {
        switch self {
        case .habit: return "repeat"
        case .task: return "checkmark.circle"
        case .measure: return "chart.bar"
        }
    }
}

/// MARK: - GoalStatus

public enum GoalStatus: String, Codable, Sendable, CaseIterable {
    case active
    case paused
    case archived
    case deleted

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .archived: return "Archived"
        case .deleted: return "Deleted"
        }
    }

    public var isVisible: Bool {
        self == .active || self == .paused
    }
}

/// MARK: - LinkedExercise

public enum LinkedExercise: String, Codable, Sendable, CaseIterable {
    case meditation
    case pomodoro
    case study
    case breath
    case water
    case affirmations
    case journal
    case mood

    public var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .pomodoro: return "Pomodoro"
        case .study: return "Study Session"
        case .breath: return "Breathing Exercise"
        case .water: return "Water Tracking"
        case .affirmations: return "Affirmations"
        case .journal: return "Journaling"
        case .mood: return "Mood Check"
        }
    }

    public var icon: String {
        switch self {
        case .meditation: return "figure.mind.and.body"
        case .pomodoro: return "timer"
        case .study: return "book"
        case .breath: return "wind"
        case .water: return "drop"
        case .affirmations: return "quote.bubble"
        case .journal: return "book.pages"
        case .mood: return "face.smiling"
        }
    }

    public var defaultEmoji: String {
        switch self {
        case .meditation: return "🧘"
        case .pomodoro: return "🍅"
        case .study: return "📚"
        case .breath: return "🌬️"
        case .water: return "💧"
        case .affirmations: return "💭"
        case .journal: return "📔"
        case .mood: return "😊"
        }
    }
}

/// MARK: - Mock Data

#if DEBUG
extension Goal {
    public static let mockMeditation = Goal(
        userId: UUID(),
        areaId: UUID(),
        title: "Morning Meditation",
        emoji: "🧘",
        kind: .habit,
        timesPerDay: 1,
        pointsPerCompletion: 10,
        linkedExerciseKey: .meditation
    )

    public static let mockWater = Goal(
        userId: UUID(),
        areaId: UUID(),
        title: "Drink Water",
        emoji: "💧",
        kind: .measure,
        timesPerDay: 8,
        pointsPerCompletion: 5,
        linkedExerciseKey: .water
    )

    public static let mockExercise = Goal(
        userId: UUID(),
        areaId: UUID(),
        title: "Workout",
        emoji: "💪",
        kind: .habit,
        timesPerDay: 1,
        pointsPerCompletion: 15,
        hashtags: ["fitness", "health"]
    )

    public static let mockTask = Goal(
        userId: UUID(),
        areaId: UUID(),
        title: "Finish project report",
        emoji: "📊",
        kind: .task,
        timesPerDay: 1,
        pointsPerCompletion: 20
    )

    public static let mockPaused = Goal(
        userId: UUID(),
        areaId: UUID(),
        title: "Learn Spanish",
        emoji: "🇪🇸",
        kind: .habit,
        status: .paused,
        timesPerDay: 1,
        pointsPerCompletion: 10
    )
}
#endif
