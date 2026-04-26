import XCTest

/// UI tests for the New Plan wizard day selection screen.
///
/// Constitution Principle II: covers the P1 user journey (US1).
/// Skipped on CI until authenticated simulator state is configured.
final class DaySelectionUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - US1: Select day → Continue → step 2 appears

    func test_selectDay_tapContinue_step2Appears() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil,
                      "UI test requires authenticated simulator state — skipped on CI")

        // Open menu
        let menuButton = app.buttons["Open menu"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        // Tap "New Workout Plan"
        let newPlanItem = app.buttons["New Workout Plan"].firstMatch
        XCTAssertTrue(newPlanItem.waitForExistence(timeout: 2))
        newPlanItem.tap()

        // Wizard opens — wait for step 1
        let wizard = app.otherElements["newPlanWizard"]
        XCTAssertTrue(wizard.waitForExistence(timeout: 3))

        // Wait for loading to finish (GET may return quickly in test environment)
        // Tap Monday to ensure at least one day is selected
        let mondayRow = app.buttons["Monday"].firstMatch
        if mondayRow.waitForExistence(timeout: 3) {
            mondayRow.tap()
        }

        // Tap Continue
        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.tap()

        // Verify step 2 of wizard is presented (step rail advances)
        // A step-2 element would be a ConfigureDayStepView with a session name field
        let sessionNameField = app.textFields.firstMatch
        XCTAssertTrue(sessionNameField.waitForExistence(timeout: 3),
                      "Step 2 (session name input) must appear after successful day save")
    }
}
