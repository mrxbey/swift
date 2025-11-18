import Foundation

/// A scheduled instance of a goal on a specific date
@Observable
public final class GoalOccurrence: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var goalId: UUID
    public var userId: UUID
    public var scheduledDate: Date
    public var dueAt: Date?
    public var status: OccurrenceStatus
    public var targetCount: Int
    public var completedCount: Int
    public var keepUntilComplete: Bool
    public var rolledFromId: UUID?
    public var rolledIntoId: UUID?
    public var nameOverride: String?
    public var emojiOverride: String?
    public var contentSnapshot: ContentSnapshot?
    public var isOneTime: Bool
    public let createdAt: Date
    public var updatedAt: Date

    /// MARK: - Lifecycle

    public init(
        id: UUID = UUID(),
        goalId: UUID,
        userId: UUID,
        scheduledDate: Date,
        dueAt: Date? = nil,
        status: OccurrenceStatus = .pending,
        targetCount: Int = 1,
        completedCount: Int = 0,
        keepUntilComplete: Bool = false,
        rolledFromId: UUID? = nil,
        rolledIntoId: UUID? = nil,
        nameOverride: String? = nil,
        emojiOverride: String? = nil,
        contentSnapshot: ContentSnapshot? = nil,
        isOneTime: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.userId = userId
        self.scheduledDate = scheduledDate
        self.dueAt = dueAt
        self.status = status
        self.targetCount = max(targetCount, 1)
        self.completedCount = max(completedCount, 0)
        self.keepUntilComplete = keepUntilComplete
        self.rolledFromId = rolledFromId
        self.rolledIntoId = rolledIntoId
        self.nameOverride = nameOverride
        self.emojiOverride = emojiOverride
        self.contentSnapshot = contentSnapshot
        self.isOneTime = isOneTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// MARK: - Computed Properties

    public var displayTitle: String {
        nameOverride ?? contentSnapshot?.title ?? "Untitled"
    }

    public var displayEmoji: String? {
        emojiOverride ?? contentSnapshot?.emoji
    }

    public var displayName: String {
        if let emoji = displayEmoji {
            return "\(emoji) \(displayTitle)"
        }
        return displayTitle
    }

    public var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1.0)
    }

    public var isComplete: Bool {
        status == .completed || completedCount >= targetCount
    }

    public var isPending: Bool {
        status == .pending
    }

    public var isSkipped: Bool {
        status == .skipped
    }

    public var isMissed: Bool {
        status == .missed
    }

    public var canComplete: Bool {
        isPending && completedCount < targetCount
    }

    public var wasRolledOver: Bool {
        rolledFromId != nil
    }

    public var wasRolledInto: Bool {
        rolledIntoId != nil
    }

    public var pointsEarned: Int {
        guard isComplete, let snapshot = contentSnapshot else { return 0 }
        return snapshot.points
    }

    /// MARK: - Methods

    public func incrementCompletion() {
        guard completedCount < targetCount else { return }
        completedCount += 1
        if completedCount >= targetCount {
            status = .completed
        }
    }

    public func decrementCompletion() {
        guard completedCount > 0 else { return }
        completedCount -= 1
        if status == .completed {
            status = .pending
        }
    }

    public func markSkipped() {
        status = .skipped
    }

    public func markMissed() {
        status = .missed
    }

    public func markCancelled() {
        status = .cancelled
    }

    /// MARK: - Equatable

    public static func == (lhs: GoalOccurrence, rhs: GoalOccurrence) -> Bool {
        lhs.id == rhs.id &&
        lhs.status == rhs.status &&
        lhs.completedCount == rhs.completedCount &&
        lhs.nameOverride == rhs.nameOverride
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - OccurrenceStatus

public enum OccurrenceStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case completed
    case skipped
    case missed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .missed: return "Missed"
        case .cancelled: return "Cancelled"
        }
    }

    public var icon: String {
        switch self {
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "arrow.right.circle"
        case .missed: return "xmark.circle"
        case .cancelled: return "slash.circle"
        }
    }

    public var color: String {
        switch self {
        case .pending: return "gray"
        case .completed: return "green"
        case .skipped: return "blue"
        case .missed: return "red"
        case .cancelled: return "orange"
        }
    }

    public var isActionable: Bool {
        self == .pending
    }

    public var isFinal: Bool {
        self == .completed || self == .skipped || self == .missed || self == .cancelled
    }
}

/// MARK: - ContentSnapshot

/// Snapshot of goal content at the time of occurrence creation
public struct ContentSnapshot: Codable, Sendable, Equatable, Hashable {
    public var title: String
    public var emoji: String?
    public var points: Int

    public init(
        title: String,
        emoji: String? = nil,
        points: Int = 5
    ) {
        self.title = title
        self.emoji = emoji
        self.points = points
    }

    public init(from goal: Goal) {
        self.title = goal.title
        self.emoji = goal.emoji
        self.points = goal.pointsPerCompletion
    }
}

/// MARK: - Mock Data

#if DEBUG
extension GoalOccurrence {
    public static let mockPending = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date(),
        status: .pending,
        targetCount: 1,
        completedCount: 0,
        contentSnapshot: .init(title: "Morning Meditation", emoji: "🧘", points: 10)
    )

    public static let mockCompleted = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date(),
        status: .completed,
        targetCount: 1,
        completedCount: 1,
        contentSnapshot: .init(title: "Workout", emoji: "💪", points: 15)
    )

    public static let mockPartial = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date(),
        status: .pending,
        targetCount: 8,
        completedCount: 5,
        contentSnapshot: .init(title: "Drink Water", emoji: "💧", points: 5)
    )

    public static let mockSkipped = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date().addingTimeInterval(-86400), // Yesterday
        status: .skipped,
        targetCount: 1,
        completedCount: 0,
        contentSnapshot: .init(title: "Study Spanish", emoji: "🇪🇸", points: 10)
    )

    public static let mockMissed = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date().addingTimeInterval(-172800), // 2 days ago
        status: .missed,
        targetCount: 1,
        completedCount: 0,
        contentSnapshot: .init(title: "Read Book", emoji: "📚", points: 10)
    )

    public static let mockRolledOver = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date(),
        status: .pending,
        targetCount: 3,
        completedCount: 0,
        keepUntilComplete: true,
        rolledFromId: UUID(),
        contentSnapshot: .init(title: "Important Task", emoji: "⭐", points: 20)
    )

    public static let mockRenamed = GoalOccurrence(
        goalId: UUID(),
        userId: UUID(),
        scheduledDate: Date(),
        status: .pending,
        targetCount: 1,
        completedCount: 0,
        nameOverride: "Special Day Meditation",
        emojiOverride: "✨",
        contentSnapshot: .init(title: "Morning Meditation", emoji: "🧘", points: 10)
    )
}
#endif
