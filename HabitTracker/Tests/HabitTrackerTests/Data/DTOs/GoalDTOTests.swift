import XCTest
@testable import HabitTracker

final class GoalDTOTests: XCTestCase {

    // MARK: - Domain to DTO Conversion

    func testInitFromDomain() {
        // Given
        let goal = TestFixtures.makeGoal(
            title: "Morning Run",
            emoji: "🏃",
            kind: .tick,
            timesPerDay: 1,
            pointsPerCompletion: 10,
            hashtags: ["fitness", "morning"]
        )

        // When
        let dto = GoalDTO(from: goal)

        // Then
        XCTAssertEqual(dto.id, goal.id)
        XCTAssertEqual(dto.userId, goal.userId)
        XCTAssertEqual(dto.areaId, goal.areaId)
        XCTAssertEqual(dto.title, "Morning Run")
        XCTAssertEqual(dto.emoji, "🏃")
        XCTAssertEqual(dto.kind, "tick")
        XCTAssertEqual(dto.status, "active")
        XCTAssertEqual(dto.keepUntilComplete, false)
        XCTAssertEqual(dto.timesPerDay, 1)
        XCTAssertEqual(dto.pointsPerCompletion, 10)
        XCTAssertEqual(dto.hashtags, ["fitness", "morning"])
    }

    func testInitFromDomainWithMeasureKind() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .measure)

        // When
        let dto = GoalDTO(from: goal)

        // Then
        XCTAssertEqual(dto.kind, "measure")
    }

    func testInitFromDomainWithArchivedStatus() {
        // Given
        let goal = TestFixtures.makeGoal(status: .archived)

        // When
        let dto = GoalDTO(from: goal)

        // Then
        XCTAssertEqual(dto.status, "archived")
    }

    // MARK: - DTO to Domain Conversion

    func testToDomain() {
        // Given
        let dto = TestFixtures.makeGoalDTO(
            title: "Water Intake",
            emoji: "💧",
            kind: "measure",
            hashtags: ["health", "hydration"]
        )

        // When
        let goal = dto.toDomain

        // Then
        XCTAssertEqual(goal.id, dto.id)
        XCTAssertEqual(goal.userId, dto.userId)
        XCTAssertEqual(goal.areaId, dto.areaId)
        XCTAssertEqual(goal.title, "Water Intake")
        XCTAssertEqual(goal.emoji, "💧")
        XCTAssertEqual(goal.kind, .measure)
        XCTAssertEqual(goal.status, .active)
        XCTAssertEqual(goal.hashtags, ["health", "hydration"])
    }

    // MARK: - GoalKind Conversion

    func testGoalKindTickConversion() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .tick)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.kind, .tick)
    }

    func testGoalKindMeasureConversion() {
        // Given
        let goal = TestFixtures.makeGoal(kind: .measure)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.kind, .measure)
    }

    // MARK: - Status Conversion

    func testStatusActiveConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .active)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .active)
    }

    func testStatusArchivedConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .archived)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .archived)
    }

    func testStatusDeletedConversion() {
        // Given
        let goal = TestFixtures.makeGoal(status: .deleted)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.status, .deleted)
    }

    // MARK: - Round Trip Conversion

    func testRoundTripConversionPreservesAllFields() {
        // Given
        let originalGoal = TestFixtures.makeGoal(
            title: "Complete Project",
            emoji: "📝",
            kind: .tick,
            status: .active,
            keepUntilComplete: true,
            timesPerDay: 3,
            pointsPerCompletion: 25,
            linkedExerciseKey: "pushups",
            hashtags: ["work", "important"]
        )

        // When
        let dto = GoalDTO(from: originalGoal)
        let convertedGoal = dto.toDomain

        // Then
        XCTAssertEqual(convertedGoal.id, originalGoal.id)
        XCTAssertEqual(convertedGoal.userId, originalGoal.userId)
        XCTAssertEqual(convertedGoal.areaId, originalGoal.areaId)
        XCTAssertEqual(convertedGoal.title, originalGoal.title)
        XCTAssertEqual(convertedGoal.emoji, originalGoal.emoji)
        XCTAssertEqual(convertedGoal.kind, originalGoal.kind)
        XCTAssertEqual(convertedGoal.status, originalGoal.status)
        XCTAssertEqual(convertedGoal.keepUntilComplete, originalGoal.keepUntilComplete)
        XCTAssertEqual(convertedGoal.timesPerDay, originalGoal.timesPerDay)
        XCTAssertEqual(convertedGoal.pointsPerCompletion, originalGoal.pointsPerCompletion)
        XCTAssertEqual(convertedGoal.linkedExerciseKey, originalGoal.linkedExerciseKey)
        XCTAssertEqual(convertedGoal.hashtags, originalGoal.hashtags)
    }

    // MARK: - Codable Tests

    func testCodableDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "\(TestFixtures.goalId.uuidString)",
            "user_id": "\(TestFixtures.userId.uuidString)",
            "area_id": "\(TestFixtures.areaId.uuidString)",
            "title": "Test Goal",
            "emoji": "🎯",
            "kind": "tick",
            "status": "active",
            "keep_until_complete": false,
            "times_per_day": 1,
            "points_per_completion": 10,
            "linked_exercise_key": null,
            "hashtags": ["test"],
            "created_at": "2023-11-14T12:00:00Z",
            "updated_at": "2023-11-14T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // When
        let dto = try decoder.decode(GoalDTO.self, from: json)

        // Then
        XCTAssertEqual(dto.id, TestFixtures.goalId)
        XCTAssertEqual(dto.title, "Test Goal")
        XCTAssertEqual(dto.emoji, "🎯")
        XCTAssertEqual(dto.kind, "tick")
        XCTAssertEqual(dto.hashtags, ["test"])
    }

    // MARK: - Edge Cases

    func testEmptyHashtags() {
        // Given
        let goal = TestFixtures.makeGoal(hashtags: [])

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.hashtags, [])
    }

    func testNilLinkedExerciseKey() {
        // Given
        let goal = TestFixtures.makeGoal(linkedExerciseKey: nil)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertNil(converted.linkedExerciseKey)
    }

    func testMultipleHashtags() {
        // Given
        let hashtags = ["health", "fitness", "morning", "routine", "2023"]
        let goal = TestFixtures.makeGoal(hashtags: hashtags)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.hashtags, hashtags)
    }

    func testZeroPointsPerCompletion() {
        // Given
        let goal = TestFixtures.makeGoal(pointsPerCompletion: 0)

        // When
        let dto = GoalDTO(from: goal)
        let converted = dto.toDomain

        // Then
        XCTAssertEqual(converted.pointsPerCompletion, 0)
    }
}
