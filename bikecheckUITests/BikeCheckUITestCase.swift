import XCTest

class BikeCheckUITestCase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Wait for loading to complete and login screen to appear
        XCTAssertTrue(app.buttons["Demo Mode"].waitForExistence(timeout: 10), "Demo Mode button should appear on login screen")

        // Use Demo Mode button to load test data and sign in
        app.buttons["Demo Mode"].tap()

        // Handle post-login onboarding if it appears
        let onboardingOverlay = app.otherElements.containing(.staticText, identifier: "Welcome to BikeCheck!")
        if onboardingOverlay.element.waitForExistence(timeout: 5) {
            // Skip onboarding to get to main app
            app.buttons["Skip Tour"].tap()
        }

        // Wait for main app to be visible
        XCTAssertTrue(app.tabBars["Tab Bar"].waitForExistence(timeout: 10), "Main app should be visible after demo mode login")
    }
    
    override func tearDown() {
        // Reset app state after each test to ensure clean slate for next test
        app.launchEnvironment = ["RESET_APP_STATE": "true"]
        app.launch()
        app.terminate()
        super.tearDown()
    }
    
    // Helper methods for common UI test operations
    func navigateToTab(_ tabName: String) {
        let tabButton = app.tabBars["Tab Bar"].buttons[tabName]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 5))
        tabButton.tap()
    }
    
    func verifyNavigationBar(_ title: String) -> Bool {
        return app.navigationBars[title].waitForExistence(timeout: 5)
    }
}