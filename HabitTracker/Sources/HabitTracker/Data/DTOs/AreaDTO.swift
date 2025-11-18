import Foundation

/// Data Transfer Object for Area entity
///
/// Maps between the PostgreSQL `areas` table (snake_case) and the Swift `Area` domain model (camelCase).
public struct AreaDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let emoji: String?
    public let colorHex: String?
    public let status: String
    public let createdAt: Date
    public let updatedAt: Date

    /// MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case emoji
        case colorHex = "color_hex"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// MARK: - Initialization

    /// Creates a DTO from a domain model
    ///
    /// - Parameter area: The domain Area model
    public init(from area: Area) {
        self.id = area.id
        self.userId = area.userId
        self.name = area.name
        self.emoji = area.emoji
        self.colorHex = area.colorHex
        self.status = area.status.rawValue
        self.createdAt = area.createdAt
        self.updatedAt = area.updatedAt
    }

    /// MARK: - Conversion

    /// Converts the DTO to a domain model
    public var toDomain: Area {
        Area(
            id: id,
            userId: userId,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            status: AreaStatus(rawValue: status) ?? .active,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
