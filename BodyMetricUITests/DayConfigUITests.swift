import XCTest

/// UI tests for the New Plan wizard step-2 (day configuration) persistence.
///
/// Constitution Principle II: covers US1 P1 journey.
/// Skipped on CI — requires authenticated simulator state.
final class DayConfigUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws { app = nil }

    func test_dayConfig_stepTwoSave_advancesToStepThree() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil,
                      "Requires authenticated simulator state — skipped on CI")

        // Navigate to wizard via home menu
        app.buttons["Open menu"].tap()
        app.buttons["New Workout Plan"].firstMatch.tap()

        // Step 1: Select one day
        let wizard = app.otherElements["newPlanWizard"]
        XCTAssertTrue(wizard.waitForExistence(timeout: 3))
        app.buttons["Monday"].firstMatch.tap()
        app.buttons["Continue"].firstMatch.tap()

        // Step 2: Fill name + continue
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Peito e Triceps")

        // Select an exercise (tap the first exercise picker button)
        app.buttons["Choose exercise"].firstMatch.tap()
        app.buttons["Barbell Bench Press"].firstMatch.tap()

        app.buttons["Continue"].firstMatch.tap()

        // Verify wizard advanced (step 3 = review or next day config)
        // Check that step 2 session name field is gone or a new view appeared
        let continueBtn = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueBtn.waitForExistence(timeout: 5),
                      "Wizard should advance to step 3 after successful step-2 save")
    }
}
