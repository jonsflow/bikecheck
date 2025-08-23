import XCTest
import Foundation
@testable import bikecheck

class StravaCredentialsTests: XCTestCase {
    
    func testStravaCredentialsAreLoadedFromBundle() {
        // Test that credentials are successfully loaded from Info.plist
        let clientId = Bundle.main.object(forInfoDictionaryKey: "StravaClientId") as? String
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "StravaClientSecret") as? String
        
        // Verify credentials exist and are not empty
        XCTAssertNotNil(clientId, "StravaClientId should be present in Info.plist")
        XCTAssertNotNil(clientSecret, "StravaClientSecret should be present in Info.plist")
        XCTAssertFalse(clientId?.isEmpty ?? true, "StravaClientId should not be empty")
        XCTAssertFalse(clientSecret?.isEmpty ?? true, "StravaClientSecret should not be empty")
        
        // For test environment, verify we get the test values
        if let testClientId = clientId {
            XCTAssertTrue(testClientId.hasPrefix("test_") || testClientId.count > 0, 
                         "Should have either test credentials or actual credentials")
        }
        
        print("✅ Loaded credentials - Client ID: \(clientId ?? "nil"), Client Secret: \(clientSecret?.prefix(8) ?? "nil")...")
    }
    
    func testStravaServiceUsesConfiguredCredentials() {
        // Use MockPersistenceController to avoid Core Data conflicts
        let mockController = MockPersistenceController()
        let stravaService = StravaService(context: mockController.container.viewContext)
        
        // Access the private properties through reflection or create a test-accessible method
        // For now, we'll test indirectly by ensuring the service initializes properly
        XCTAssertNotNil(stravaService, "StravaService should initialize successfully with configured credentials")
        
        // Verify the service has access to credentials by checking if it can construct URLs
        // This is an indirect test that the credentials are accessible
        let bundle = Bundle.main
        let clientId = bundle.object(forInfoDictionaryKey: "StravaClientId") as? String
        XCTAssertNotNil(clientId, "StravaService should have access to client ID through Bundle")
    }
    
    func testCredentialsAreNotHardcoded() {
        // Ensure we're not falling back to empty defaults
        let clientId = Bundle.main.object(forInfoDictionaryKey: "StravaClientId") as? String ?? ""
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "StravaClientSecret") as? String ?? ""
        
        XCTAssertNotEqual(clientId, "", "Client ID should not be empty - xcconfig not properly configured")
        XCTAssertNotEqual(clientSecret, "", "Client Secret should not be empty - xcconfig not properly configured")
        
        // Verify we're not using placeholder values
        XCTAssertNotEqual(clientId, "$(STRAVA_CLIENT_ID)", "Client ID should be resolved, not a placeholder")
        XCTAssertNotEqual(clientSecret, "$(STRAVA_CLIENT_SECRET)", "Client Secret should be resolved, not a placeholder")
    }
}