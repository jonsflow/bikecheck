import XCTest

/// UI tests validating that the service interval list reflects updates after a last service date
/// change. This covers the bug where list cards showed stale data after navigating back from
/// the detail view.
///
/// Test data setup (StravaService.insertTestData):
///   - Bike 1 (Specialized Turbo Kenevo Expert) has 14h of rides and its chain interval
///     has lastServiceDate = 10 days ago. With a 5h interval this puts it at 280% usage
///     — status "Now" (overdue). This simulates the user having set an old service date.
final class ServiceIntervalListUpdateUITests: BikeCheckUITestCase {

    /// Verifies the list correctly shows "Now" for the overdue chain interval before any reset.
    func testOverdueIntervalAppearsInList() {
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))

        XCTAssertTrue(
            app.staticTexts["Now"].waitForExistence(timeout: 5),
            "The chain interval with a 10-day-old service date should appear as overdue in the list"
        )
    }

    /// After a Log Service reset the list must immediately reflect the new "Good" status
    /// without requiring an app restart.
    ///
    /// Before the fix this test exposed the bug — the list showed a stale "Now" status
    /// after navigating back because ServiceViewModel wasn't reloading and
    /// ServiceIntervalCardView wasn't being re-rendered due to SwiftUI's reference-type
    /// diffing skipping the body evaluation.
    func testListUpdatesAfterLogServiceReset() {
        navigateToTab("Service Intervals")
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))

        // Confirm the overdue "Now" status is visible before touching anything
        XCTAssertTrue(
            app.staticTexts["Now"].waitForExistence(timeout: 5),
            "Pre-condition: overdue chain interval should be visible in the list"
        )

        // Tap the specific cell showing "Now" — not positional, so sort order doesn't matter
        let overdueCell = app.cells.containing(.staticText, identifier: "Now").firstMatch
        XCTAssertTrue(overdueCell.waitForExistence(timeout: 3))
        overdueCell.tap()

        // Reset to today via Log Service
        let resetButton = app.buttons["Reset Interval"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))
        resetButton.tap()

        let logServiceNav = app.navigationBars["Log Service"]
        XCTAssertTrue(logServiceNav.waitForExistence(timeout: 5))
        logServiceNav.buttons["Log Service"].tap()

        // Navigate back to the list
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(verifyNavigationBar("Service Intervals"))

        // The list must now reflect the reset — "Now" gone, "Good" visible.
        // With the old bug, stale data kept "Now" visible until app restart.
        XCTAssertFalse(
            app.staticTexts["Now"].waitForExistence(timeout: 2),
            "After reset the interval should no longer appear as overdue"
        )
        XCTAssertTrue(
            app.staticTexts["Good"].waitForExistence(timeout: 3),
            "After reset the chain interval should show Good status"
        )
    }
}
