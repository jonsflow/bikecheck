import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()

        // Explicitly clear onboarding flag for these tests
        app.launchArguments = ["UI_TESTING", "CLEAR_ONBOARDING"]

        app.launch()
    }
    
    override func tearDown() {
        // Reset app state after each test to ensure clean slate for next test
        app.launchEnvironment = ["RESET_APP_STATE": "true"]
        app.launch()
        app.terminate()
        super.tearDown()
    }
    
    func testOnboardingFlow() throws {
        // Wait for loading and login screen to appear
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10), "Demo Mode button should appear")

        // Tap Demo Mode to authenticate
        app.buttons["Demo Mode"].tap()

        // Verify onboarding overlay appears AFTER login (post-authentication)
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5), "Onboarding overlay should appear after login")

        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)

        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)

        // Take the tour to start the interactive tour
        app.buttons["Take the Tour"].tap()

        // Verify onboarding welcome overlay is dismissed
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))

        // Step 1: Service Intervals
        XCTAssertTrue(app.staticTexts["Monitor Maintenance"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Step 2: Bikes
        XCTAssertTrue(app.staticTexts["Manage Your Fleet"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Step 3: Activities
        XCTAssertTrue(app.staticTexts["Track Your Rides"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // Step 4: Complete
        XCTAssertTrue(app.staticTexts["Tour Complete!"].waitForExistence(timeout: 3))
        app.buttons["Finish"].tap()

        // Verify tour is dismissed and main app is visible
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Should show main app after tour completion")

        // Terminate and relaunch app to verify onboarding doesn't show again
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "RESET_APP_STATE")
        // Remove CLEAR_ONBOARDING flag to preserve UserDefaults state
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // User is still signed in, tour already completed
        // Should go DIRECTLY to main app - no login screen, no onboarding
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2), "Onboarding should not appear after tour completion")
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 10), "Should show main app directly after relaunch")
    }
    
    func testOnboardingSkipTour() throws {
        // Wait for loading and login screen to appear
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10), "Demo Mode button should appear")

        // Tap Demo Mode to authenticate
        app.buttons["Demo Mode"].tap()

        // Verify onboarding overlay appears AFTER login
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5), "Onboarding overlay should appear after login")

        // Verify welcome content exists
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)

        // Skip onboarding to complete it
        app.buttons["Skip Tour"].tap()

        // Verify main app is visible
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5))

        // Sign out to return to login screen
        app.tabBars["Tab Bar"].buttons["Service Intervals"].tap()
        // Navigate to profile and sign out (implementation depends on your profile navigation)

        // Terminate and relaunch app to test persistence (without reset flag)
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "RESET_APP_STATE")
        // Remove CLEAR_ONBOARDING flag to preserve UserDefaults state
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // User is still signed in, onboarding already completed
        // Should go DIRECTLY to main app - no login screen, no onboarding
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2), "Onboarding should not appear after relaunch")
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 10), "Should show main app directly after relaunch")
    }
}
