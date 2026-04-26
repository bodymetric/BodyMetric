import XCTest

/// UI tests for the home menu dropdown and New Plan wizard navigation.
///
/// Constitution Principle II: UI tests cover the P1 user journey.
/// Run against a real simulator after adding all source files to the Xcode target.
final class HomeMenuUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - US1: open menu + navigate to wizard

    /// Verifies that tapping the mascot chip opens the dropdown menu.
    func test_tapMascotChip_opensMenu() throws {
        // Skip on CI until full simulator login flow is configured
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil,
                      "UI tests require authenticated simulator state — skipped on CI")

        let menuTrigger = app.buttons["Open menu"]
        XCTAssertTrue(menuTrigger.waitForExistence(timeout: 5))
        menuTrigger.tap()

        let menuPanel = app.otherElements["homeMenuPanel"]
        XCTAssertTrue(menuPanel.waitForExistence(timeout: 2),
                      "homeMenuPanel must appear after tapping the mascot chip")
    }

    /// Verifies that tapping "New Workout Plan" presents the wizard screen.
    func test_tapNewWorkoutPlan_presentsWizard() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil,
                      "UI tests require authenticated simulator state — skipped on CI")

        app.buttons["Open menu"].tap()
        app.buttons["New Workout Plan"].firstMatch.tap()

        let wizard = app.otherElements["newPlanWizard"]
        XCTAssertTrue(wizard.waitForExistence(timeout: 2),
                      "newPlanWizard must appear after tapping New Workout Plan")
    }

    // MARK: - US2: dismiss menu

    func test_closeButton_dismissesMenu() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] != nil,
                      "UI tests require authenticated simulator state — skipped on CI")

        app.buttons["Open menu"].tap()
        XCTAssertTrue(app.otherElements["homeMenuPanel"].waitForExistence(timeout: 2))

        app.buttons["Close menu"].tap()
        XCTAssertFalse(app.otherElements["homeMenuPanel"].exists,
                       "Menu panel must disappear after close button tap")
    }
}
