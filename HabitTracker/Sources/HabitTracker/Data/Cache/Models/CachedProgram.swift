import Foundation
import SwiftData

/// SwiftData model for caching Program entities locally
///
/// Mirrors the Program domain model but adds sync metadata for offline-first functionality.
@Model
public final class CachedProgram {
    @Attribute(.unique) public var id: UUID
    public var slug: String?
    public var title: String
    public var summary: String?
    public var category: String?
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData"))
    public var tags: [String]
    public var thumbnailURL: String?
    public var heroURL: String?
    public var wideURL: String?
    public var ratingAvg: Double?
    public var addedCount: Int
    public var visibility: String
    public var createdAt: Date
    public var updatedAt: Date

    // Sync metadata
    public var lastSyncedAt: Date?
    public var syncState: String // "synced", "pending", "failed"
    public var pendingOperation: String? // "create", "update", "delete"

    /// MARK: - Initialization

    public init(
        id: UUID,
        slug: String? = nil,
        title: String,
        summary: String? = nil,
        category: String? = nil,
        tags: [String],
        thumbnailURL: String? = nil,
        heroURL: String? = nil,
        wideURL: String? = nil,
        ratingAvg: Double? = nil,
        addedCount: Int,
        visibility: String,
        createdAt: Date,
        updatedAt: Date,
        lastSyncedAt: Date? = nil,
        syncState: String = "synced",
        pendingOperation: String? = nil
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.category = category
        self.tags = tags
        self.thumbnailURL = thumbnailURL
        self.heroURL = heroURL
        self.wideURL = wideURL
        self.ratingAvg = ratingAvg
        self.addedCount = addedCount
        self.visibility = visibility
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.syncState = syncState
        self.pendingOperation = pendingOperation
    }

    /// MARK: - Conversion

    /// Creates a cached model from a domain model
    public convenience init(from program: Program, syncState: SyncState = .synced) {
        self.init(
            id: program.id,
            slug: program.slug,
            title: program.title,
            summary: program.summary,
            category: program.category,
            tags: program.tags,
            thumbnailURL: program.thumbnailURL,
            heroURL: program.heroURL,
            wideURL: program.wideURL,
            ratingAvg: program.ratingAvg,
            addedCount: program.addedCount,
            visibility: program.visibility.rawValue,
            createdAt: program.createdAt,
            updatedAt: program.updatedAt,
            lastSyncedAt: syncState == .synced ? Date() : nil,
            syncState: syncState.rawValue,
            pendingOperation: nil
        )
    }

    /// Converts to domain model
    public func toDomain() -> Program {
        Program(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            richText: nil, // RichText not cached for simplicity
            category: category,
            tags: tags,
            thumbnailURL: thumbnailURL,
            heroURL: heroURL,
            wideURL: wideURL,
            ratingAvg: ratingAvg,
            addedCount: addedCount,
            visibility: ProgramVisibility(rawValue: visibility) ?? .public,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Updates from domain model
    public func update(from program: Program, syncState: SyncState = .pending) {
        self.slug = program.slug
        self.title = program.title
        self.summary = program.summary
        self.category = program.category
        self.tags = program.tags
        self.thumbnailURL = program.thumbnailURL
        self.heroURL = program.heroURL
        self.wideURL = program.wideURL
        self.ratingAvg = program.ratingAvg
        self.addedCount = program.addedCount
        self.visibility = program.visibility.rawValue
        self.updatedAt = program.updatedAt
        self.syncState = syncState.rawValue
        if syncState == .synced {
            self.lastSyncedAt = Date()
        }
    }
}
