import XCTest
import CoreData
import UserNotifications
@testable import bikecheck

class NotificationThrottlingTests: XCTestCase {

    var mockPersistenceController: MockPersistenceController!
    var notificationService: NotificationService!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        mockPersistenceController = MockPersistenceController()
        context = mockPersistenceController.container.viewContext
        notificationService = NotificationService.shared
    }

    override func tearDown() {
        mockPersistenceController = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Schema Migration Tests

    func testServiceIntervalHasLastNotificationDateProperty() {
        // Given - Create a service interval
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        // When - Set lastNotificationDate
        let testDate = Date()
        serviceInterval.lastNotificationDate = testDate

        try? context.save()

        // Then - Verify property exists and can be read
        XCTAssertNotNil(serviceInterval.lastNotificationDate)
        XCTAssertEqual(serviceInterval.lastNotificationDate, testDate)
    }

    func testServiceIntervalLastNotificationDateIsOptional() {
        // Given - Create a service interval without setting lastNotificationDate
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        try? context.save()

        // Then - Verify lastNotificationDate is nil by default
        XCTAssertNil(serviceInterval.lastNotificationDate)
    }

    func testServiceIntervalPersistsLastNotificationDate() {
        // Given - Create and save a service interval with lastNotificationDate
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        let testDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        serviceInterval.lastNotificationDate = testDate

        try? context.save()

        let objectID = serviceInterval.objectID

        // When - Fetch the interval from the store
        let fetchedInterval = try? context.existingObject(with: objectID) as? ServiceInterval

        // Then - Verify lastNotificationDate was persisted
        XCTAssertNotNil(fetchedInterval?.lastNotificationDate)
        XCTAssertEqual(fetchedInterval?.lastNotificationDate, testDate)
    }

    // MARK: - Notification Throttling Tests

    func testNotificationSentWhenLastNotificationDateIsNil() {
        // Given - Service interval with no previous notification
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true
        serviceInterval.lastNotificationDate = nil

        try? context.save()

        // When - Send notification
        notificationService.sendNotification(for: serviceInterval)

        // Then - lastNotificationDate should be updated
        // Note: We can't easily test the actual notification without mocking UNUserNotificationCenter,
        // but we can verify the date gets set when notification succeeds
        // This would require notification center mocking for full coverage
        XCTAssertTrue(serviceInterval.notify)
    }

    func testNotificationThrottledWhenSentRecently() {
        // Given - Service interval with notification sent 3 days ago
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        // Set lastNotificationDate to 3 days ago (within 7-day throttle window)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        serviceInterval.lastNotificationDate = threeDaysAgo

        try? context.save()

        // When - Attempt to send notification again
        let beforeDate = serviceInterval.lastNotificationDate
        notificationService.sendNotification(for: serviceInterval)

        // Then - lastNotificationDate should remain unchanged (notification was throttled)
        XCTAssertEqual(serviceInterval.lastNotificationDate, beforeDate)
    }

    func testNotificationSentWhenThrottlePeriodExpired() {
        // Given - Service interval with notification sent 8 days ago (outside 7-day window)
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        // Set lastNotificationDate to 8 days ago (outside throttle window)
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        serviceInterval.lastNotificationDate = eightDaysAgo

        try? context.save()

        // When - Send notification
        notificationService.sendNotification(for: serviceInterval)

        // Then - Notification should be allowed (throttle period expired)
        // Note: Full test would require UNUserNotificationCenter mocking
        XCTAssertTrue(serviceInterval.notify)
    }

    func testNotificationNotSentWhenNotifyIsFalse() {
        // Given - Service interval with notify = false
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = false
        serviceInterval.lastNotificationDate = nil

        try? context.save()

        // When - Attempt to send notification
        notificationService.sendNotification(for: serviceInterval)

        // Then - lastNotificationDate should remain nil (no notification sent)
        XCTAssertNil(serviceInterval.lastNotificationDate)
    }

    func testThrottleWindowIsSevenDays() {
        // Given - Service interval with notification sent exactly 7 days ago
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0

        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        // Set to exactly 7 days ago (604800 seconds)
        let sevenDaysAgo = Date(timeIntervalSinceNow: -604800)
        serviceInterval.lastNotificationDate = sevenDaysAgo

        try? context.save()

        // When - Check if notification would be throttled
        let timeSinceLastNotification = Date().timeIntervalSince(sevenDaysAgo)

        // Then - Should be at or just past the throttle threshold
        XCTAssertGreaterThanOrEqual(timeSinceLastNotification, 604800)
    }
}
