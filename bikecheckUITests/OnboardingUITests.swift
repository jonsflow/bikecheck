import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDown() {
        // Reset app state after each test to ensure clean slate for next test
        app.launchEnvironment = ["RESET_APP_STATE": "true"]
        app.launch()
        app.terminate()
        super.tearDown()
    }

    func testOnboardingFlowComplete() throws {
        // Verify onboarding overlay appears on first launch
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 5), "Onboarding overlay should appear on first launch")

        // Take the tour
        app.buttons["Take the Tour"].tap()

        // Step 1: Service Intervals - "Monitor Maintenance"
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Should show main app with tour")
        XCTAssertTrue(app.staticTexts["Monitor Maintenance"].waitForExistence(timeout: 3), "Step 1: Should show Monitor Maintenance")
        XCTAssertTrue(app.staticTexts["Keep track of when your bike components need service"].exists, "Step 1: Should show correct subtitle")
        app.buttons["Next"].tap()

        // Step 2: Bikes - "Manage Your Fleet"
        XCTAssertTrue(app.staticTexts["Manage Your Fleet"].waitForExistence(timeout: 3), "Step 2: Should show Manage Your Fleet")
        XCTAssertTrue(app.staticTexts["View and manage your bikes and their details"].exists, "Step 2: Should show correct subtitle")
        app.buttons["Next"].tap()

        // Step 3: Activities - "Track Your Rides"
        XCTAssertTrue(app.staticTexts["Track Your Rides"].waitForExistence(timeout: 3), "Step 3: Should show Track Your Rides")
        XCTAssertTrue(app.staticTexts["See your riding history and mileage"].exists, "Step 3: Should show correct subtitle")
        app.buttons["Next"].tap()

        // Step 4: Complete - "Tour Complete!"
        XCTAssertTrue(app.staticTexts["Tour Complete!"].waitForExistence(timeout: 3), "Step 4: Should show Tour Complete")
        XCTAssertTrue(app.staticTexts["Ready to connect your real data or explore more? Click Finish to return to the login screen."].exists, "Step 4: Should show correct subtitle")
        app.buttons["Finish"].tap()

        // Should return to login screen
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should return to login screen after finishing tour")

        // Exit and relaunch app
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "RESET_APP_STATE")
        app.launch()

        // Verify onboarding does NOT appear on subsequent launch
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 3), "Onboarding should not appear after completion")
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should show login screen on subsequent launches")
    }

    func testOnboardingSkip() throws {
        // Verify onboarding overlay appears on first launch
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 5), "Onboarding overlay should appear on first launch")

        // Skip onboarding tour
        app.buttons["Skip Tour"].tap()

        // Verify onboarding is dismissed and user returns to login screen
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should return to login screen after skipping")

        // Exit and relaunch app
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "RESET_APP_STATE")
        app.launch()

        // Verify onboarding does NOT appear on subsequent launch
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 3), "Onboarding should not appear after skip")
        XCTAssertTrue(app.buttons["Sign in with Strava"].waitForExistence(timeout: 3), "Should show login screen on subsequent launches")
    }
}
