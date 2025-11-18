import Foundation

/// A user's reflection on their progress
///
/// Reflections allow users to journal about their experiences, challenges, and insights.
/// They can be attached to specific goals or areas, or be general reflections.
@Observable
public final class Reflection: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let goalId: UUID?
    public let areaId: UUID?
    public var content: String
    public var tags: [String]
    public var mood: ReflectionMood?
    public let reflectionDate: Date
    public let createdAt: Date
    public var updatedAt: Date

    /// MARK: - Initialization

    public init(
        id: UUID = UUID(),
        userId: UUID,
        goalId: UUID? = nil,
        areaId: UUID? = nil,
        content: String,
        tags: [String] = [],
        mood: ReflectionMood? = nil,
        reflectionDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.goalId = goalId
        self.areaId = areaId
        self.content = content
        self.tags = tags
        self.mood = mood
        self.reflectionDate = reflectionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// MARK: - Computed Properties

    /// The scope of this reflection
    public var scope: ReflectionScope {
        if goalId != nil {
            return .goal
        } else if areaId != nil {
            return .area
        } else {
            return .general
        }
    }

    /// Formatted date for display
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: reflectionDate)
    }

    /// MARK: - Equatable

    public static func == (lhs: Reflection, rhs: Reflection) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.mood == rhs.mood
    }

    /// MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// MARK: - ReflectionMood

/// Mood associated with a reflection
public enum ReflectionMood: String, Codable, Sendable, CaseIterable {
    case great = "great"
    case good = "good"
    case okay = "okay"
    case struggling = "struggling"
    case difficult = "difficult"

    public var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .struggling: return "😕"
        case .difficult: return "😞"
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}

/// MARK: - ReflectionScope

/// The scope of a reflection
public enum ReflectionScope: String, Codable, Sendable {
    case goal = "goal"
    case area = "area"
    case general = "general"

    public var displayName: String {
        switch self {
        case .goal: return "Goal Reflection"
        case .area: return "Area Reflection"
        case .general: return "General Reflection"
        }
    }
}
