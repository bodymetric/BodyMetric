import XCTest
@testable import BodyMetric

/// Unit tests for NewPlan domain models.
///
/// Constitution Principle II: written before implementation (TDD).
@MainActor
final class NewPlanModelsTests: XCTestCase {

    // MARK: - DayOfWeek

    func test_dayOfWeek_hasSevenCases() {
        XCTAssertEqual(DayOfWeek.allCases.count, 7)
    }

    func test_dayOfWeek_displayOrderIsMonToSun() {
        let order = DayOfWeek.displayOrder
        XCTAssertEqual(order.first, .monday)
        XCTAssertEqual(order.last, .sunday)
        XCTAssertEqual(order.count, 7)
    }

    func test_dayOfWeek_shortLabels() {
        XCTAssertEqual(DayOfWeek.monday.shortLabel, "Mon")
        XCTAssertEqual(DayOfWeek.tuesday.shortLabel, "Tue")
        XCTAssertEqual(DayOfWeek.wednesday.shortLabel, "Wed")
        XCTAssertEqual(DayOfWeek.thursday.shortLabel, "Thu")
        XCTAssertEqual(DayOfWeek.friday.shortLabel, "Fri")
        XCTAssertEqual(DayOfWeek.saturday.shortLabel, "Sat")
        XCTAssertEqual(DayOfWeek.sunday.shortLabel, "Sun")
    }

    func test_dayOfWeek_fullLabels() {
        XCTAssertEqual(DayOfWeek.monday.fullLabel, "Monday")
        XCTAssertEqual(DayOfWeek.sunday.fullLabel, "Sunday")
    }

    // MARK: - Exercise catalog

    func test_exerciseCatalog_containsExactlyEighteenEntries() {
        XCTAssertEqual(Exercise.catalog.count, 18)
    }

    func test_exerciseCatalog_containsEightMuscleGroups() {
        let muscles = Set(Exercise.catalog.map(\.primaryMuscle))
        XCTAssertEqual(muscles.count, 8)
    }

    func test_exerciseCatalog_idsAreUnique() {
        let ids = Exercise.catalog.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "All exercise IDs must be unique")
    }

    // MARK: - ExerciseBlock validity

    func test_exerciseBlock_isInvalidWhenExerciseIdEmpty() {
        let block = ExerciseBlock()
        XCTAssertFalse(block.isValid, "Empty exerciseId must make block invalid")
    }

    func test_exerciseBlock_isValidWithAllFieldsSet() {
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 80.0
        block.restSeconds = 90
        XCTAssertTrue(block.isValid)
    }

    func test_exerciseBlock_isInvalidWhenRepsZero() {
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 0
        XCTAssertFalse(block.isValid)
    }

    func test_exerciseBlock_isValidWhenWeightIsZero() {
        var block = ExerciseBlock()
        block.exerciseId = "plank"
        block.targetReps = 10
        block.targetWeight = 0
        block.restSeconds = 60
        XCTAssertTrue(block.isValid, "Bodyweight exercises (weight=0) should be valid")
    }

    func test_exerciseBlock_isValidWhenRestIsZero() {
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 60
        block.restSeconds = 0
        XCTAssertTrue(block.isValid, "Rest=0 is allowed")
    }

    func test_exerciseBlock_hasUniqueIdOnInit() {
        let a = ExerciseBlock()
        let b = ExerciseBlock()
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - DayPlan validity

    func test_dayPlan_isInvalidWhenSessionNameBlank() {
        var plan = DayPlan(day: .monday)
        plan.sessionName = "   "
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        plan.blocks = [block]
        XCTAssertFalse(plan.isValid)
    }

    func test_dayPlan_isInvalidWhenSessionNameEmpty() {
        let plan = DayPlan(day: .monday)
        XCTAssertFalse(plan.isValid, "Default DayPlan has empty name → invalid")
    }

    func test_dayPlan_isInvalidWhenAllBlocksAreInvalid() {
        var plan = DayPlan(day: .monday)
        plan.sessionName = "Push Day"
        plan.blocks = [ExerciseBlock()] // empty exerciseId
        XCTAssertFalse(plan.isValid)
    }

    func test_dayPlan_isInvalidWithNoBlocks() {
        var plan = DayPlan(day: .monday)
        plan.sessionName = "Push Day"
        plan.blocks = []
        XCTAssertFalse(plan.isValid)
    }

    func test_dayPlan_isValidWithNameAndValidBlocks() {
        var plan = DayPlan(day: .monday)
        plan.sessionName = "Push Day"
        var block = ExerciseBlock()
        block.exerciseId = "bench"
        block.targetReps = 8
        block.targetWeight = 80
        block.restSeconds = 90
        plan.blocks = [block]
        XCTAssertTrue(plan.isValid)
    }

    // MARK: - WorkoutPlan

    func test_workoutPlan_initializesWithAutoUUID() {
        let a = WorkoutPlan(dayPlans: [])
        let b = WorkoutPlan(dayPlans: [])
        XCTAssertNotEqual(a.id, b.id)
    }

    func test_workoutPlan_initializesWithCreatedAt() {
        let before = Date()
        let plan = WorkoutPlan(dayPlans: [])
        let after = Date()
        XCTAssertGreaterThanOrEqual(plan.createdAt, before)
        XCTAssertLessThanOrEqual(plan.createdAt, after)
    }

    func test_workoutPlan_isInvalidWhenEmpty() {
        let plan = WorkoutPlan(dayPlans: [])
        XCTAssertFalse(plan.isValid)
    }

    func test_workoutPlan_roundTripsWithCodable() throws {
        var block = ExerciseBlock()
        block.exerciseId = "squat"
        block.targetReps = 5
        block.targetWeight = 100
        block.restSeconds = 180
        var dayPlan = DayPlan(day: .friday)
        dayPlan.sessionName = "Leg Day"
        dayPlan.blocks = [block]
        let original = WorkoutPlan(dayPlans: [dayPlan])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WorkoutPlan.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.dayPlans.count, 1)
        XCTAssertEqual(decoded.dayPlans[0].sessionName, "Leg Day")
        XCTAssertEqual(decoded.dayPlans[0].blocks[0].exerciseId, "squat")
    }
}
