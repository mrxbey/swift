import XCTest
@testable import HabitTracker

final class GoalOccurrenceDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 3,
            completedCount: 1,
            status: .pending
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)

        // Then
        XCTAssertEqual(dto.id, occurrence.id)
        XCTAssertEqual(dto.userId, occurrence.userId)
        XCTAssertEqual(dto.goalId, occurrence.goalId)
        XCTAssertEqual(dto.targetCount, 3)
        XCTAssertEqual(dto.completedCount, 1)
        XCTAssertEqual(dto.status, "pending")
        XCTAssertFalse(dto.keepUntilComplete)
        XCTAssertFalse(dto.isOneTime)
    }

    func testInitFromDomainWithSnapshot() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Morning Run",
            emoji: "🏃",
            points: 15
        )
        let occurrence = TestFixtures.makeOccurrence(
            contentSnapshot: snapshot
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)

        // Then
        XCTAssertNotNil(dto.contentSnapshot)
        XCTAssertEqual(dto.contentSnapshot?.title, "Morning Run")
        XCTAssertEqual(dto.contentSnapshot?.emoji, "🏃")
        XCTAssertEqual(dto.contentSnapshot?.points, 15)
    }

    func testInitFromDomainWithOverrides() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            nameOverride: "Custom Name",
            emojiOverride: "🎯"
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)

        // Then
        XCTAssertEqual(dto.nameOverride, "Custom Name")
        XCTAssertEqual(dto.emojiOverride, "🎯")
    }

    func testInitFromDomainWithRollover() {
        // Given
        let rolledFromId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            keepUntilComplete: true,
            rolledFromId: rolledFromId
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)

        // Then
        XCTAssertTrue(dto.keepUntilComplete)
        XCTAssertEqual(dto.rolledFromId, rolledFromId)
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = TestFixtures.makeOccurrenceDTO(
            targetCount: 5,
            completedCount: 3,
            status: "pending"
        )

        // When
        let occurrence = dto.toDomain

        // Then
        XCTAssertEqual(occurrence.id, dto.id)
        XCTAssertEqual(occurrence.userId, dto.userId)
        XCTAssertEqual(occurrence.goalId, dto.goalId)
        XCTAssertEqual(occurrence.targetCount, 5)
        XCTAssertEqual(occurrence.completedCount, 3)
        XCTAssertEqual(occurrence.status, .pending)
    }

    func testToDomainWithSnapshot() {
        // Given
        let snapshotDTO = ContentSnapshotDTO(
            from: ContentSnapshot(title: "Test", emoji: "✅", points: 20)
        )
        let dto = TestFixtures.makeOccurrenceDTO(
            contentSnapshot: snapshotDTO
        )

        // When
        let occurrence = dto.toDomain

        // Then
        XCTAssertNotNil(occurrence.contentSnapshot)
        XCTAssertEqual(occurrence.contentSnapshot?.title, "Test")
        XCTAssertEqual(occurrence.contentSnapshot?.emoji, "✅")
        XCTAssertEqual(occurrence.contentSnapshot?.points, 20)
    }

    // MARK: - OccurrenceStatus Conversion

    func testStatusPendingConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .pending)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .pending)
    }

    func testStatusCompletedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .completed)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .completed)
    }

    func testStatusSkippedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .skipped)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .skipped)
    }

    func testStatusMissedConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .missed)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .missed)
    }

    func testStatusCancelledConversion() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(status: .cancelled)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .cancelled)
    }

    func testStatusUnknownDefaultsToPending() {
        // Given
        let dto = GoalOccurrenceDTO(
            id: UUID(),
            userId: TestFixtures.userId,
            goalId: TestFixtures.goalId,
            scheduleId: nil,
            scheduledDate: Date(),
            dueAt: nil,
            targetCount: 1,
            completedCount: 0,
            status: "unknown_status",
            keepUntilComplete: false,
            rolledFromId: nil,
            rolledIntoId: nil,
            nameOverride: nil,
            emojiOverride: nil,
            contentSnapshot: nil,
            isOneTime: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let occurrence = dto.toDomain

        // Then
        XCTAssertEqual(occurrence.status, .pending)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalOccurrence = TestFixtures.makeOccurrence(
            targetCount: 8,
            completedCount: 5,
            status: .pending,
            keepUntilComplete: true,
            nameOverride: "Special Task",
            emojiOverride: "⭐",
            contentSnapshot: ContentSnapshot(title: "Original", emoji: "🎯", points: 25),
            isOneTime: true
        )

        // When
        let dto = GoalOccurrenceDTO(from: originalOccurrence)
        let convertedOccurrence = dto.toDomain

        // Then
        XCTAssertEqual(convertedOccurrence.id, originalOccurrence.id)
        XCTAssertEqual(convertedOccurrence.userId, originalOccurrence.userId)
        XCTAssertEqual(convertedOccurrence.goalId, originalOccurrence.goalId)
        XCTAssertEqual(convertedOccurrence.targetCount, originalOccurrence.targetCount)
        XCTAssertEqual(convertedOccurrence.completedCount, originalOccurrence.completedCount)
        XCTAssertEqual(convertedOccurrence.status, originalOccurrence.status)
        XCTAssertEqual(convertedOccurrence.keepUntilComplete, originalOccurrence.keepUntilComplete)
        XCTAssertEqual(convertedOccurrence.nameOverride, originalOccurrence.nameOverride)
        XCTAssertEqual(convertedOccurrence.emojiOverride, originalOccurrence.emojiOverride)
        XCTAssertEqual(convertedOccurrence.contentSnapshot?.title, originalOccurrence.contentSnapshot?.title)
        XCTAssertEqual(convertedOccurrence.isOneTime, originalOccurrence.isOneTime)
    }

    // MARK: - Codable Tests

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "\(TestFixtures.occurrenceId.uuidString)",
            "user_id": "\(TestFixtures.userId.uuidString)",
            "goal_id": "\(TestFixtures.goalId.uuidString)",
            "schedule_id": null,
            "scheduled_date": "2023-11-14T00:00:00Z",
            "due_at": null,
            "target_count": 3,
            "completed_count": 1,
            "status": "pending",
            "keep_until_complete": false,
            "rolled_from_id": null,
            "rolled_into_id": null,
            "name_override": null,
            "emoji_override": null,
            "content_snapshot": {
                "title": "Test Task",
                "emoji": "🎯",
                "points": 10
            },
            "is_one_time": false,
            "created_at": "2023-11-14T12:00:00Z",
            "updated_at": "2023-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let dto = try decoder.decode(GoalOccurrenceDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.id, TestFixtures.occurrenceId)
        XCTAssertEqual(dto.targetCount, 3)
        XCTAssertEqual(dto.completedCount, 1)
        XCTAssertEqual(dto.status, "pending")
        XCTAssertNotNil(dto.contentSnapshot)
        XCTAssertEqual(dto.contentSnapshot?.title, "Test Task")
    }

    // MARK: - Edge Cases

    func testNilOptionalFields() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            dueAt: nil,
            nameOverride: nil,
            emojiOverride: nil,
            contentSnapshot: nil
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertNil(converted.dueAt)
        XCTAssertNil(converted.nameOverride)
        XCTAssertNil(converted.emojiOverride)
        XCTAssertNil(converted.contentSnapshot)
    }

    func testZeroCompletedCount() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(completedCount: 0)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.completedCount, 0)
    }

    func testHighTargetCount() {
        // Given
        let occurrence = TestFixtures.makeOccurrence(
            targetCount: 100,
            completedCount: 75
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.targetCount, 100)
        XCTAssertEqual(converted.completedCount, 75)
    }

    func testRolloverIDs() {
        // Given
        let rolledFromId = UUID()
        let rolledIntoId = UUID()
        let occurrence = TestFixtures.makeOccurrence(
            rolledFromId: rolledFromId,
            rolledIntoId: rolledIntoId
        )

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.rolledFromId, rolledFromId)
        XCTAssertEqual(converted.rolledIntoId, rolledIntoId)
    }

    func testDueAtDatePreservation() {
        // Given
        let dueDate = Date().addingTimeInterval(3600) // 1 hour from now
        let occurrence = TestFixtures.makeOccurrence(dueAt: dueDate)

        // When
        let dto = GoalOccurrenceDTO(from: occurrence)
        let converted = dto.toDomain

        // Then
        XCTAssertNotNil(converted.dueAt)
        XCTAssertEqual(
            converted.dueAt?.timeIntervalSince1970,
            dueDate.timeIntervalSince1970,
            accuracy: 0.001
        )
    }
}

// MARK: - ContentSnapshotDTOTests

final class ContentSnapshotDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Morning Meditation",
            emoji: "🧘",
            points: 15
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)

        // Then
        XCTAssertEqual(dto.title, "Morning Meditation")
        XCTAssertEqual(dto.emoji, "🧘")
        XCTAssertEqual(dto.points, 15)
    }

    func testInitFromDomainWithNilEmoji() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Task",
            emoji: nil,
            points: 5
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)

        // Then
        XCTAssertEqual(dto.title, "Task")
        XCTAssertNil(dto.emoji)
        XCTAssertEqual(dto.points, 5)
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = ContentSnapshotDTO(
            from: ContentSnapshot(title: "Workout", emoji: "💪", points: 20)
        )

        // When
        let snapshot = dto.toDomain

        // Then
        XCTAssertEqual(snapshot.title, "Workout")
        XCTAssertEqual(snapshot.emoji, "💪")
        XCTAssertEqual(snapshot.points, 20)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalSnapshot = ContentSnapshot(
            title: "Read Book",
            emoji: "📚",
            points: 25
        )

        // When
        let dto = ContentSnapshotDTO(from: originalSnapshot)
        let convertedSnapshot = dto.toDomain

        // Then
        XCTAssertEqual(convertedSnapshot.title, originalSnapshot.title)
        XCTAssertEqual(convertedSnapshot.emoji, originalSnapshot.emoji)
        XCTAssertEqual(convertedSnapshot.points, originalSnapshot.points)
    }

    // MARK: - Codable Tests

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "title": "Daily Exercise",
            "emoji": "🏋️",
            "points": 30
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()

        // When
        let dto = try decoder.decode(ContentSnapshotDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.title, "Daily Exercise")
        XCTAssertEqual(dto.emoji, "🏋️")
        XCTAssertEqual(dto.points, 30)
    }

    func testCodableEncodingToJSON() throws {
        // Given
        let snapshot = ContentSnapshot(
            title: "Study",
            emoji: "📖",
            points: 15
        )
        let dto = ContentSnapshotDTO(from: snapshot)

        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(dto)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Then
        XCTAssertEqual(json["title"] as? String, "Study")
        XCTAssertEqual(json["emoji"] as? String, "📖")
        XCTAssertEqual(json["points"] as? Int, 15)
    }

    // MARK: - Edge Cases

    func testEmptyTitle() {
        // Given
        let snapshot = ContentSnapshot(
            title: "",
            emoji: "🎯",
            points: 10
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.title, "")
    }

    func testZeroPoints() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Task",
            emoji: "✅",
            points: 0
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.points, 0)
    }

    func testHighPoints() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Major Achievement",
            emoji: "🏆",
            points: 1000
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.points, 1000)
    }

    func testSpecialCharactersInTitle() {
        // Given
        let snapshot = ContentSnapshot(
            title: "Test: @#$%^&*() Title!",
            emoji: "🎉",
            points: 5
        )

        // When
        let dto = ContentSnapshotDTO(from: snapshot)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.title, "Test: @#$%^&*() Title!")
    }

    func testUnicodeEmoji() {
        // Given
        let emojis = ["👨‍👩‍👧‍👦", "🏳️‍🌈", "👍🏽", "🇺🇸"]

        for emoji in emojis {
            // When
            let snapshot = ContentSnapshot(title: "Test", emoji: emoji, points: 10)
            let dto = ContentSnapshotDTO(from: snapshot)
            let converted = dto.toDomain

            // Then
            XCTAssertEqual(converted.emoji, emoji)
        }
    }
}
