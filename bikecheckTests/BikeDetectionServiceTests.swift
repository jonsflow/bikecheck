//
//  BikeDetectionServiceTests.swift
//  bikecheckTests
//
//  Created by Claude on 2026-02-12.
//

import XCTest
@testable import bikecheck

final class BikeDetectionServiceTests: XCTestCase {
    var service: BikeDetectionService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        service = BikeDetectionService.shared
    }

    override func tearDownWithError() throws {
        service = nil
        try super.tearDownWithError()
    }

    // MARK: - Configuration Loading Tests

    func testLoadBikeDatabase() throws {
        XCTAssertNotNil(service.bikeDatabase, "BikeDatabase should load successfully")

        if let database = service.bikeDatabase {
            XCTAssertGreaterThan(database.bikeDefinitions.count, 0, "BikeDatabase should contain bike definitions")
        }
    }

    func testLoadPresetConfig() throws {
        XCTAssertNotNil(service.presetConfig, "BikePresets.yaml should load successfully")

        if let config = service.presetConfig {
            XCTAssertEqual(config.version, "1.0", "Config version should be 1.0")
            XCTAssertGreaterThan(config.bikeTypes.count, 0, "Should have bike type definitions")
            XCTAssertGreaterThan(config.manufacturers.count, 0, "Should have manufacturer presets")
        }
    }

    // MARK: - Exact Model Match Tests (High Confidence)

    func testExactModelMatch_TrekFuelEX() throws {
        let result = service.detectBike(name: "Trek Fuel EX 9.8")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek manufacturer")
        XCTAssertEqual(result.model, "Fuel EX", "Should detect Fuel EX model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence for exact match")
        XCTAssertFalse(result.suggestedIntervals.isEmpty, "Should have suggested intervals")
        XCTAssertTrue(result.suggestedIntervals.contains("chain"), "Should include chain interval")
        XCTAssertTrue(result.suggestedIntervals.contains("fork_lowers"), "Should include fork_lowers interval")
        XCTAssertTrue(result.suggestedIntervals.contains("rear_shock"), "Should include rear_shock interval")
    }

    func testExactModelMatch_SpecializedStumpjumper() throws {
        let result = service.detectBike(name: "Specialized Stumpjumper Evo")

        XCTAssertEqual(result.manufacturer, "Specialized", "Should detect Specialized manufacturer")
        XCTAssertEqual(result.model, "Stumpjumper", "Should detect Stumpjumper model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
    }

    func testExactModelMatch_SantaCruzHightower() throws {
        let result = service.detectBike(name: "Santa Cruz Hightower CC")

        XCTAssertEqual(result.manufacturer, "Santa Cruz", "Should detect Santa Cruz manufacturer")
        XCTAssertEqual(result.model, "Hightower", "Should detect Hightower model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
    }

    func testExactModelMatch_RoadBike() throws {
        let result = service.detectBike(name: "Trek Domane SL 5")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek manufacturer")
        XCTAssertEqual(result.model, "Domane", "Should detect Domane model")
        XCTAssertEqual(result.type, .rigid, "Should detect rigid/road bike type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
        XCTAssertTrue(result.suggestedIntervals.contains("cassette"), "Road bikes should include cassette")
        XCTAssertFalse(result.suggestedIntervals.contains("rear_shock"), "Road bikes should not include rear_shock")
    }

    func testExactModelMatch_Hardtail() throws {
        let result = service.detectBike(name: "Trek X-Caliber 9")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek manufacturer")
        XCTAssertEqual(result.model, "X-Caliber", "Should detect X-Caliber model")
        XCTAssertEqual(result.type, .hardtail, "Should detect hardtail type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
        XCTAssertTrue(result.suggestedIntervals.contains("fork_lowers"), "Hardtails should include fork_lowers")
        XCTAssertFalse(result.suggestedIntervals.contains("rear_shock"), "Hardtails should not include rear_shock")
    }

    func testExactModelMatch_GravelBike() throws {
        let result = service.detectBike(name: "Trek Checkpoint ALR 5")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek manufacturer")
        XCTAssertEqual(result.model, "Checkpoint", "Should detect Checkpoint model")
        XCTAssertEqual(result.type, .gravel, "Should detect gravel type")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
        XCTAssertTrue(result.suggestedIntervals.contains("grips_tape"), "Gravel bikes should include grips_tape")
    }

    // MARK: - Case Insensitivity Tests

    func testCaseInsensitive_Lowercase() throws {
        let result = service.detectBike(name: "trek fuel ex")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek despite lowercase")
        XCTAssertEqual(result.model, "Fuel EX", "Should detect Fuel EX despite lowercase")
        XCTAssertEqual(result.confidence, .high, "Should have high confidence")
    }

    func testCaseInsensitive_Uppercase() throws {
        let result = service.detectBike(name: "SPECIALIZED STUMPJUMPER")

        XCTAssertEqual(result.manufacturer, "Specialized", "Should detect Specialized despite uppercase")
        XCTAssertEqual(result.model, "Stumpjumper", "Should detect Stumpjumper despite uppercase")
    }

    func testCaseInsensitive_MixedCase() throws {
        let result = service.detectBike(name: "SaNtA cRuZ hIgHtOwEr")

        XCTAssertEqual(result.manufacturer, "Santa Cruz", "Should detect Santa Cruz despite mixed case")
        XCTAssertEqual(result.model, "Hightower", "Should detect Hightower despite mixed case")
    }

    // MARK: - Alias Matching Tests

    func testAliasMatching_SantaCruz() throws {
        let result1 = service.detectBike(name: "SC Hightower")
        XCTAssertEqual(result1.manufacturer, "Santa Cruz", "Should match 'SC' alias to Santa Cruz")

        let result2 = service.detectBike(name: "SantaCruz Hightower")
        XCTAssertEqual(result2.manufacturer, "Santa Cruz", "Should match 'SantaCruz' (no space) to Santa Cruz")
    }

    func testAliasMatching_ModelAlias() throws {
        let result = service.detectBike(name: "Trek FuelEx")
        XCTAssertEqual(result.model, "Fuel EX", "Should match 'FuelEx' alias to 'Fuel EX'")
    }

    func testAliasMatching_Stumpjumper() throws {
        let result = service.detectBike(name: "Specialized Stumpy")
        XCTAssertEqual(result.model, "Stumpjumper", "Should match 'Stumpy' alias to 'Stumpjumper'")
    }

    // MARK: - Multi-Word Model Tests

    func testMultiWordModel_FuelEX() throws {
        let result = service.detectBike(name: "Trek Fuel EX 9.8 2024")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect manufacturer with multi-word model")
        XCTAssertEqual(result.model, "Fuel EX", "Should detect multi-word model 'Fuel EX'")
    }

    func testMultiWordModel_TopFuel() throws {
        let result = service.detectBike(name: "Trek Top Fuel 9.9")

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect Trek")
        XCTAssertEqual(result.model, "Top Fuel", "Should detect multi-word model 'Top Fuel'")
    }

    func testMultiWordModel_TurboLevo() throws {
        let result = service.detectBike(name: "Specialized Turbo Levo Expert")

        XCTAssertEqual(result.manufacturer, "Specialized", "Should detect Specialized")
        XCTAssertEqual(result.model, "Turbo Levo", "Should detect multi-word model 'Turbo Levo'")
    }

    // MARK: - Database Fallback Tests (Medium Confidence)

    func testDatabaseFallback() throws {
        // This test assumes BikeDatabase.json contains bikes not in BikePresets.yaml
        // If a bike is in the database but not in presets, it should fall back to database match

        // For now, test that database is loaded and can be queried
        XCTAssertNotNil(service.bikeDatabase, "Database should be loaded for fallback")
    }

    // MARK: - Unknown Bike Tests (Fallback Confidence)

    func testUnknownBike_NoManufacturer() throws {
        let result = service.detectBike(name: "My Custom Bike")

        XCTAssertNil(result.manufacturer, "Should not detect manufacturer for unknown bike")
        XCTAssertNil(result.model, "Should not detect model for unknown bike")
        XCTAssertEqual(result.type, .unknown, "Should return unknown type")
        XCTAssertEqual(result.confidence, .fallback, "Should have fallback confidence")
        XCTAssertTrue(result.suggestedIntervals.isEmpty, "Should have no suggested intervals")
    }

    func testUnknownBike_RandomBrand() throws {
        let result = service.detectBike(name: "UnknownBrand X1 Pro")

        XCTAssertEqual(result.confidence, .fallback, "Should have fallback confidence for unknown brand")
        XCTAssertEqual(result.type, .unknown, "Should return unknown type")
    }

    // MARK: - Edge Case Tests

    func testEmptyString() throws {
        let result = service.detectBike(name: "")

        XCTAssertEqual(result.confidence, .fallback, "Empty string should result in fallback")
        XCTAssertEqual(result.type, .unknown, "Empty string should return unknown type")
    }

    func testWhitespaceOnly() throws {
        let result = service.detectBike(name: "   ")

        XCTAssertEqual(result.confidence, .fallback, "Whitespace only should result in fallback")
        XCTAssertEqual(result.type, .unknown, "Whitespace only should return unknown type")
    }

    func testSpecialCharacters() throws {
        let result = service.detectBike(name: "Trek Fuel EX 9.8 (2024) - Carbon")

        XCTAssertEqual(result.manufacturer, "Trek", "Should handle special characters")
        XCTAssertEqual(result.model, "Fuel EX", "Should detect model despite special characters")
    }

    func testNumbersInName() throws {
        let result = service.detectBike(name: "Trek FX 3 Disc")

        // This might not match exactly, but should not crash
        XCTAssertNotNil(result, "Should handle numbers in bike name")
    }

    func testVeryLongBikeName() throws {
        let longName = "Trek Fuel EX 9.8 GX Carbon Full Suspension Mountain Bike 2024 Special Edition with Extra Features"
        let result = service.detectBike(name: longName)

        XCTAssertEqual(result.manufacturer, "Trek", "Should detect manufacturer in long name")
        XCTAssertEqual(result.model, "Fuel EX", "Should detect model in long name")
    }

    // MARK: - Default Intervals Tests

    func testGetDefaultIntervalsForType_FullSuspension() throws {
        let intervals = service.getDefaultIntervalsForType(.fullSuspension)

        XCTAssertTrue(intervals.contains("chain"), "Full suspension should include chain")
        XCTAssertTrue(intervals.contains("fork_lowers"), "Full suspension should include fork_lowers")
        XCTAssertTrue(intervals.contains("rear_shock"), "Full suspension should include rear_shock")
        XCTAssertTrue(intervals.contains("dropper_post"), "Full suspension should include dropper_post")
        XCTAssertTrue(intervals.contains("brake_pads"), "Full suspension should include brake_pads")
    }

    func testGetDefaultIntervalsForType_Hardtail() throws {
        let intervals = service.getDefaultIntervalsForType(.hardtail)

        XCTAssertTrue(intervals.contains("chain"), "Hardtail should include chain")
        XCTAssertTrue(intervals.contains("fork_lowers"), "Hardtail should include fork_lowers")
        XCTAssertTrue(intervals.contains("brake_pads"), "Hardtail should include brake_pads")
        XCTAssertFalse(intervals.contains("rear_shock"), "Hardtail should NOT include rear_shock")
    }

    func testGetDefaultIntervalsForType_Rigid() throws {
        let intervals = service.getDefaultIntervalsForType(.rigid)

        XCTAssertTrue(intervals.contains("chain"), "Road bike should include chain")
        XCTAssertTrue(intervals.contains("cassette"), "Road bike should include cassette")
        XCTAssertTrue(intervals.contains("brake_pads"), "Road bike should include brake_pads")
        XCTAssertTrue(intervals.contains("grips_tape"), "Road bike should include grips_tape")
        XCTAssertFalse(intervals.contains("fork_lowers"), "Road bike should NOT include fork_lowers")
        XCTAssertFalse(intervals.contains("rear_shock"), "Road bike should NOT include rear_shock")
    }

    // MARK: - Multiple Manufacturer Tests

    func testMultipleManufacturers_Canyon() throws {
        let result = service.detectBike(name: "Canyon Spectral CF 8")

        XCTAssertEqual(result.manufacturer, "Canyon", "Should detect Canyon manufacturer")
        XCTAssertEqual(result.model, "Spectral", "Should detect Spectral model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension")
    }

    func testMultipleManufacturers_Yeti() throws {
        let result = service.detectBike(name: "Yeti SB130 Lunch Ride")

        XCTAssertEqual(result.manufacturer, "Yeti", "Should detect Yeti manufacturer")
        XCTAssertEqual(result.model, "SB130", "Should detect SB130 model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension")
    }

    func testMultipleManufacturers_Giant() throws {
        let result = service.detectBike(name: "Giant Trance X Advanced Pro 29")

        XCTAssertEqual(result.manufacturer, "Giant", "Should detect Giant manufacturer")
        XCTAssertEqual(result.model, "Trance", "Should detect Trance model")
        XCTAssertEqual(result.type, .fullSuspension, "Should detect full suspension")
    }

    func testMultipleManufacturers_Pivot() throws {
        let result = service.detectBike(name: "Pivot Switchblade V2")

        XCTAssertEqual(result.manufacturer, "Pivot", "Should detect Pivot manufacturer")
        XCTAssertEqual(result.model, "Switchblade", "Should detect Switchblade model")
    }

    // MARK: - Performance Tests

    func testDetectionPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = service.detectBike(name: "Trek Fuel EX 9.8")
            }
        }
    }
}
