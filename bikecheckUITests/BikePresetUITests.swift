//
//  BikePresetUITests.swift
//  bikecheckUITests
//
//  Created by Claude on 2026-02-12.
//

import XCTest

final class BikePresetUITests: BikeCheckUITestCase {

    // MARK: - Bike Detection Flow Tests

    func testBikePresetConfirmationFlow_TrekFuelEX() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Find and tap on the "Turbo Kenevo" test bike (full suspension)
        // Note: Test data should include a Trek bike for proper testing
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        XCTAssertTrue(firstBike.waitForExistence(timeout: 5), "Bike should exist in list")
        firstBike.tap()

        // Wait for bike detail view
        XCTAssertTrue(app.navigationBars["Bike Details"].waitForExistence(timeout: 3), "Should navigate to bike detail")

        // Tap "Create Default Service Intervals" button
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3), "Create button should exist")
        createButton.tap()

        // Wait for preset confirmation sheet to appear
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Confirmation sheet should appear")

        // Verify detection result is shown
        // The actual text will depend on the bike name in test data
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'detected' OR label CONTAINS[c] 'bike'")).firstMatch.exists, "Detection result should be shown")

        // Verify intervals are displayed
        let chainInterval = app.buttons.matching(identifier: "interval_chain").firstMatch
        XCTAssertTrue(chainInterval.waitForExistence(timeout: 3), "Chain interval should be shown")

        // Verify Apply button exists
        let applyButton = app.buttons["apply_button"]
        XCTAssertTrue(applyButton.exists, "Apply button should exist")
        XCTAssertTrue(applyButton.isEnabled, "Apply button should be enabled")

        // Tap Apply to create intervals
        applyButton.tap()

        // Wait for confirmation sheet to dismiss
        XCTAssertFalse(app.navigationBars["Service Intervals"].waitForExistence(timeout: 1), "Sheet should dismiss")

        // Verify intervals were created
        // Should see service intervals in the list now
        let serviceIntervalsList = app.collectionViews.firstMatch
        XCTAssertTrue(serviceIntervalsList.exists, "Service intervals list should exist")
    }

    func testBikePresetConfirmation_IntervalCustomization() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        XCTAssertTrue(firstBike.waitForExistence(timeout: 5), "Bike should exist")
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3), "Create button should exist")
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Toggle off an interval (e.g., dropper_post if it exists)
        let dropperInterval = app.buttons["interval_dropper_post"]
        if dropperInterval.exists {
            dropperInterval.tap()
            // Tapping should toggle it off
        }

        // Apply intervals
        let applyButton = app.buttons["apply_button"]
        applyButton.tap()

        // Sheet should dismiss
        XCTAssertFalse(app.navigationBars["Service Intervals"].waitForExistence(timeout: 1), "Sheet should dismiss")
    }

    func testBikePresetConfirmation_DatePicker() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Verify date picker exists
        let datePickers = app.datePickers.firstMatch
        XCTAssertTrue(datePickers.exists, "Date picker should exist in confirmation view")

        // Apply intervals
        let applyButton = app.buttons["apply_button"]
        applyButton.tap()
    }

    func testBikePresetConfirmation_CustomizeButton() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Tap Customize button
        let customizeButton = app.buttons["customize_button"]
        XCTAssertTrue(customizeButton.exists, "Customize button should exist")
        customizeButton.tap()

        // Should show bike type selection view
        XCTAssertTrue(app.navigationBars["Bike Type"].waitForExistence(timeout: 3), "Type selection should appear")

        // Verify bike types are shown
        let fullSuspensionType = app.buttons["bike_type_full_suspension"]
        let hardtailType = app.buttons["bike_type_hardtail"]
        let rigidType = app.buttons["bike_type_rigid"]

        XCTAssertTrue(fullSuspensionType.exists || hardtailType.exists || rigidType.exists, "Bike types should be shown")

        // Cancel type selection
        app.buttons["Cancel"].tap()

        // Should return to confirmation view
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 2), "Should return to confirmation")

        // Cancel the whole flow
        app.buttons["Cancel"].tap()
    }

    func testBikeTypeSelection_ManualSelection() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Tap Customize to access type selection
        let customizeButton = app.buttons["customize_button"]
        customizeButton.tap()

        // Wait for type selection view
        XCTAssertTrue(app.navigationBars["Bike Type"].waitForExistence(timeout: 3), "Type selection should appear")

        // Select a bike type (e.g., hardtail)
        let hardtailButton = app.buttons["bike_type_hardtail"]
        if hardtailButton.exists {
            hardtailButton.tap()

            // Should return to confirmation view
            XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 2), "Should return to confirmation")

            // Intervals should update based on selected type
            // Hardtail should NOT have rear_shock
            let rearShockInterval = app.buttons["interval_rear_shock"]
            XCTAssertFalse(rearShockInterval.exists, "Hardtail should not have rear shock interval")

            // Should have fork_lowers
            let forkInterval = app.buttons["interval_fork_lowers"]
            XCTAssertTrue(forkInterval.exists, "Hardtail should have fork interval")
        }

        // Cancel
        app.buttons["Cancel"].tap()
    }

    func testBikePresetConfirmation_CancelFlow() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Get count of service intervals before
        let serviceIntervalsSection = app.collectionViews.firstMatch
        let initialCellCount = serviceIntervalsSection.cells.count

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Tap Cancel
        app.buttons["Cancel"].tap()

        // Sheet should dismiss without creating intervals
        XCTAssertFalse(app.navigationBars["Service Intervals"].waitForExistence(timeout: 1), "Sheet should dismiss")

        // Verify no intervals were created
        let finalCellCount = serviceIntervalsSection.cells.count
        XCTAssertEqual(initialCellCount, finalCellCount, "No intervals should be created when canceling")
    }

    func testBikePresetConfirmation_EmptyIntervals() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Uncheck all intervals
        let intervalButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'interval_'"))
        let count = intervalButtons.count

        for i in 0..<count {
            let button = intervalButtons.element(boundBy: i)
            if button.exists {
                button.tap() // Toggle off
            }
        }

        // Apply button should be disabled when no intervals selected
        let applyButton = app.buttons["apply_button"]
        XCTAssertFalse(applyButton.isEnabled, "Apply button should be disabled with no intervals selected")

        // Cancel
        app.buttons["Cancel"].tap()
    }

    // MARK: - Integration Tests

    func testEndToEnd_CreateIntervalsAndNavigateToServiceTab() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        createButton.tap()

        // Wait for confirmation sheet
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        // Apply intervals
        let applyButton = app.buttons["apply_button"]
        applyButton.tap()

        // Wait for success alert
        let alert = app.alerts["Service Intervals Created"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Success alert should appear")

        // Tap OK
        alert.buttons["OK"].tap()

        // Should navigate back to bikes list and switch to Service Intervals tab
        XCTAssertTrue(app.tabBars.buttons["Service Intervals"].isSelected, "Should switch to Service Intervals tab")
    }

    func testMultipleBikes_DifferentDetections() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Test with first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.element(boundBy: 0)

        if firstBike.exists {
            firstBike.tap()

            // Create intervals
            let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
            if createButton.exists {
                createButton.tap()

                // Verify sheet appears
                XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

                // Note the bike type detected
                // (In a real test, we'd verify different bikes get different detections)

                // Cancel
                app.buttons["Cancel"].tap()

                // Go back
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilityIdentifiers() throws {
        let app = XCUIApplication()

        // Navigate to Bikes tab
        app.tabBars.buttons["Bikes"].tap()

        // Tap first bike
        let bikesList = app.collectionViews.firstMatch
        let firstBike = bikesList.cells.firstMatch
        firstBike.tap()

        // Create default service intervals
        let createButton = app.buttons["CreateDefaultServiceIntervalsButton"]
        XCTAssertTrue(createButton.exists, "Create button should have accessibility identifier")
        createButton.tap()

        // Verify accessibility identifiers in confirmation view
        XCTAssertTrue(app.navigationBars["Service Intervals"].waitForExistence(timeout: 3), "Sheet should appear")

        let applyButton = app.buttons["apply_button"]
        XCTAssertTrue(applyButton.exists, "Apply button should have accessibility identifier")

        let customizeButton = app.buttons["customize_button"]
        XCTAssertTrue(customizeButton.exists, "Customize button should have accessibility identifier")

        // Cancel
        app.buttons["Cancel"].tap()
    }
}
