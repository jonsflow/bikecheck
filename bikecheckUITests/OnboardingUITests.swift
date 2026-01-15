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

        // Take the tour to complete onboarding and load test data
        app.buttons["Take the Tour"].tap()

        // Verify onboarding overlay is dismissed and main content is visible
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Main app should be visible after onboarding completion")
    }
    
    func testOnboardingSkipTour() throws {
        // Wait for loading and login screen to appear
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10), "Demo Mode button should appear")

        // Tap Demo Mode to authenticate
        app.buttons["Demo Mode"].tap()

        // Verify onboarding overlay appears AFTER login
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 5), "Onboarding overlay should appear after login")

        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)

        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)

        // Tap Skip Tour to bypass onboarding
        app.buttons["Skip Tour"].tap()

        // Verify onboarding overlay is dismissed and main app is visible
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Should show main app after skipping tour")
    }
    
    func testOnboardingButtonInteraction() throws {
        // Wait for loading and login screen to appear
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10), "Demo Mode button should appear")

        // Tap Demo Mode to authenticate
        app.buttons["Demo Mode"].tap()

        // Verify onboarding overlay appears AFTER login
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        XCTAssertTrue(onboardingOverlay.element.waitForExistence(timeout: 10), "Onboarding overlay should appear after login")

        // Verify welcome step content
        XCTAssertTrue(app.staticTexts["Welcome to BikeCheck!"].exists)
        XCTAssertTrue(app.staticTexts["Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."].exists)

        // Verify choice buttons exist
        XCTAssertTrue(app.buttons["Skip Tour"].exists)
        XCTAssertTrue(app.buttons["Take the Tour"].exists)

        // Choose "Take the Tour" to complete onboarding
        app.buttons["Take the Tour"].tap()

        // Verify onboarding is dismissed
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5))
    }
    
    func testOnboardingPersistence() throws {
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
        app.launch()

        // Wait for login screen
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10))

        // Sign in again with Demo Mode
        app.buttons["Demo Mode"].tap()

        // Verify onboarding does NOT appear on subsequent logins (already completed)
        XCTAssertFalse(app.staticTexts["Welcome to BikeCheck!"].waitForExistence(timeout: 3), "Onboarding should not appear on subsequent logins")
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 5), "Should show main app directly on subsequent logins")
    }
}
