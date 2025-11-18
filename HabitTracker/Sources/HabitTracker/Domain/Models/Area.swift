import Foundation

/// Life area for organizing goals (work, health, personal, etc.)
@Observable
public final class Area: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var userId: UUID
    public var name: String
    public var emoji: String?
    public var colorHex: String?
    public var status: AreaStatus
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        emoji: String? = nil,
        colorHex: String? = nil,
        status: AreaStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Equatable

    public static func == (lhs: Area, rhs: Area) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.emoji == rhs.emoji &&
        lhs.colorHex == rhs.colorHex &&
        lhs.status == rhs.status
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - AreaStatus

public enum AreaStatus: String, Codable, Sendable, CaseIterable {
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

// MARK: - Mock Data (for previews and testing)

#if DEBUG
extension Area {
    public static let mock = Area(
        userId: UUID(),
        name: "Health & Fitness",
        emoji: "💪",
        colorHex: "#FF6B6B",
        status: .active
    )

    public static let mockWork = Area(
        userId: UUID(),
        name: "Work",
        emoji: "💼",
        colorHex: "#4ECDC4",
        status: .active
    )

    public static let mockPersonal = Area(
        userId: UUID(),
        name: "Personal Growth",
        emoji: "🌱",
        colorHex: "#95E1D3",
        status: .active
    )

    public static let mockPaused = Area(
        userId: UUID(),
        name: "Travel",
        emoji: "✈️",
        colorHex: "#F38181",
        status: .paused
    )
}
#endif
