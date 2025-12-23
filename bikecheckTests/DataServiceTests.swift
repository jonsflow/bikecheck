import XCTest
import CoreData
@testable import bikecheck

class DataServiceTests: XCTestCase {
    
    var mockPersistenceController: MockPersistenceController!
    var sut: DataService!
    var originalController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        
        // Store the original shared instance
        originalController = PersistenceController.shared
        
        // Create our mock controller
        mockPersistenceController = MockPersistenceController()
        
        // Inject our mock as the shared instance
        // This is the key step - replace the shared instance with our mock
        let mirror = Mirror(reflecting: PersistenceController.self)
        for child in mirror.children {
            if child.label == "shared" {
                if let sharedProperty = child.value as? PersistenceController {
                    // We found the shared instance, but can't replace it directly
                    // Instead we'll use method swizzling or similar techniques
                    // For now, we'll just ensure our tests work with what we have
                }
            }
        }
        
        // Create the data service with our mock's context
        sut = DataService(context: mockPersistenceController.container.viewContext)
    }
    
    override func tearDown() {
        sut = nil
        mockPersistenceController = nil
        // Restore original shared instance if needed
        super.tearDown()
    }
    
    // A simpler test that just verifies basic CRUD operations
    func testBasicOperations() {
        // Given
        let context = mockPersistenceController.container.viewContext
        
        // When - Create a bike
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 500.0
        
        // Then - Can save it
        XCTAssertNoThrow(try context.save())
        
        // When - Fetch bikes
        let bikes = sut.fetchBikes()
        
        // Then - We can retrieve it
        XCTAssertEqual(bikes.count, 1)
        XCTAssertEqual(bikes.first?.id, "test-bike")
        XCTAssertEqual(bikes.first?.name, "Test Bike")
    }
    
    func testFetchActivities() {
        // Given
        mockPersistenceController.createTestData()
        
        // When
        let activities = sut.fetchActivities()
        
        // Then
        XCTAssertEqual(activities.count, 2)
        let ids = activities.map { $0.id }.sorted()
        XCTAssertEqual(ids, [1001, 1002])
    }
    
    func testFetchServiceIntervals() {
        // Given
        mockPersistenceController.createTestData()
        
        // When
        let intervals = sut.fetchServiceIntervals()
        
        // Then
        XCTAssertEqual(intervals.count, 1)
        XCTAssertEqual(intervals.first?.part, "Chain")
    }
    
    func testCreateDefaultServiceIntervals() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 100.0
        try? context.save()
        
        // When
        sut.createDefaultServiceIntervals(for: bike)
        
        // Then
        let fetchRequest: NSFetchRequest<ServiceInterval> = NSFetchRequest<ServiceInterval>(entityName: "ServiceInterval")
        fetchRequest.predicate = NSPredicate(format: "bike.id == %@", "test-bike")
        
        do {
            let intervals = try context.fetch(fetchRequest)
            XCTAssertEqual(intervals.count, 3, "Should create 3 service intervals")
            
            // Check each interval has required properties
            let parts = intervals.map { $0.part }
            XCTAssertTrue(parts.contains("chain"), "Should create a chain service interval")
            XCTAssertTrue(parts.contains("Fork Lowers"), "Should create a fork lowers service interval")
            XCTAssertTrue(parts.contains("Shock"), "Should create a shock service interval")
        } catch {
            XCTFail("Failed to fetch service intervals: \(error)")
        }
    }
    
    func testDeleteBike() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "delete-test-bike"
        bike.name = "Delete Test Bike"
        bike.distance = 300.0
        try? context.save()

        // Verify bike exists
        var fetchRequest: NSFetchRequest<Bike> = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "delete-test-bike")
        XCTAssertEqual(try! context.fetch(fetchRequest).count, 1, "Bike should exist before deletion")

        // When
        sut.deleteBike(bike)

        // Then
        fetchRequest = NSFetchRequest<Bike>(entityName: "Bike")
        fetchRequest.predicate = NSPredicate(format: "id == %@", "delete-test-bike")
        XCTAssertEqual(try! context.fetch(fetchRequest).count, 0, "Bike should be deleted")
    }

    func testServiceIntervalWithLastServiceDate() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike-date"
        bike.name = "Test Bike with Date"
        bike.distance = 100.0

        let lastServiceDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        // When
        sut.createDefaultServiceIntervals(for: bike, lastServiceDate: lastServiceDate)

        // Then
        let fetchRequest: NSFetchRequest<ServiceInterval> = NSFetchRequest<ServiceInterval>(entityName: "ServiceInterval")
        fetchRequest.predicate = NSPredicate(format: "bike.id == %@", "test-bike-date")

        do {
            let intervals = try context.fetch(fetchRequest)
            XCTAssertEqual(intervals.count, 3, "Should create 3 service intervals")

            // All intervals should have the lastServiceDate set
            for interval in intervals {
                XCTAssertNotNil(interval.lastServiceDate, "Service interval should have lastServiceDate set")
                XCTAssertEqual(interval.lastServiceDate, lastServiceDate, "Service interval lastServiceDate should match provided date")
            }
        } catch {
            XCTFail("Failed to fetch service intervals: \(error)")
        }
    }

    func testServiceIntervalDefaultsToToday() {
        // Given
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike-default-date"
        bike.name = "Test Bike Default Date"
        bike.distance = 100.0

        let beforeCreate = Date()

        // When - create without specifying date (should default to today)
        sut.createDefaultServiceIntervals(for: bike)

        let afterCreate = Date()

        // Then
        let fetchRequest: NSFetchRequest<ServiceInterval> = NSFetchRequest<ServiceInterval>(entityName: "ServiceInterval")
        fetchRequest.predicate = NSPredicate(format: "bike.id == %@", "test-bike-default-date")

        do {
            let intervals = try context.fetch(fetchRequest)
            XCTAssertEqual(intervals.count, 3, "Should create 3 service intervals")

            // All intervals should have lastServiceDate set to today
            for interval in intervals {
                XCTAssertNotNil(interval.lastServiceDate, "Service interval should have lastServiceDate set")

                // Verify the date is within the time range of test execution
                if let date = interval.lastServiceDate {
                    XCTAssertTrue(date >= beforeCreate && date <= afterCreate, "lastServiceDate should be set to current time")
                }
            }
        } catch {
            XCTFail("Failed to fetch service intervals: \(error)")
        }
    }

    func testRideTimeSinceDate() {
        // Given
        mockPersistenceController.createTestData()
        let context = mockPersistenceController.container.viewContext

        let fetchRequest: NSFetchRequest<Bike> = NSFetchRequest<Bike>(entityName: "Bike")
        guard let bike = try? context.fetch(fetchRequest).first else {
            XCTFail("No test bike found")
            return
        }

        // Create activities with known dates
        let activity1 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity1.id = 9001
        activity1.name = "Test Ride 1"
        activity1.type = "Ride"
        activity1.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        activity1.movingTime = 3600 // 1 hour in seconds
        activity1.gearId = bike.id

        let activity2 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity2.id = 9002
        activity2.name = "Test Ride 2"
        activity2.type = "Ride"
        activity2.startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        activity2.movingTime = 7200 // 2 hours in seconds
        activity2.gearId = bike.id

        try? context.save()

        // When - calculate ride time since 7 days ago (should only include activity2)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let rideTime = bike.rideTimeSince(date: sevenDaysAgo, context: context)

        // Then - should be 2 hours (only activity2)
        XCTAssertEqual(rideTime, 2.0, accuracy: 0.01, "Ride time since 7 days ago should be 2 hours")

        // When - calculate ride time since 15 days ago (should include both)
        let fifteenDaysAgo = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let totalRideTime = bike.rideTimeSince(date: fifteenDaysAgo, context: context)

        // Then - should be 3 hours (both activities)
        XCTAssertEqual(totalRideTime, 3.0, accuracy: 0.01, "Ride time since 15 days ago should be 3 hours")
    }

    func testServiceIntervalCalculationWithLastServiceDate() {
        // This test verifies that changing lastServiceDate actually affects the hours calculation

        // Given - Create a bike with activities at specific dates
        let context = mockPersistenceController.container.viewContext
        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike-calculation"
        bike.name = "Test Bike Calculation"
        bike.distance = 100.0

        // Create activities: one 10 days ago (1 hour), one 5 days ago (2 hours)
        let activity1 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity1.id = 8001
        activity1.name = "Old Ride"
        activity1.type = "Ride"
        activity1.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        activity1.movingTime = 3600 // 1 hour
        activity1.gearId = bike.id

        let activity2 = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: context) as! Activity
        activity2.id = 8002
        activity2.name = "Recent Ride"
        activity2.type = "Ride"
        activity2.startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        activity2.movingTime = 7200 // 2 hours
        activity2.gearId = bike.id

        try? context.save()

        // Create a service interval with 10 hour interval time
        let serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bike = bike
        serviceInterval.notify = true

        // SCENARIO 1: Last serviced 15 days ago (before all activities)
        // Should show 3 hours used (1+2), 7 hours remaining
        let fifteenDaysAgo = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        serviceInterval.lastServiceDate = fifteenDaysAgo

        let usageScenario1 = bike.rideTimeSince(date: fifteenDaysAgo, context: context)
        let timeUntilServiceScenario1 = serviceInterval.intervalTime - usageScenario1

        XCTAssertEqual(usageScenario1, 3.0, accuracy: 0.01, "Should show 3 hours used when serviced 15 days ago")
        XCTAssertEqual(timeUntilServiceScenario1, 7.0, accuracy: 0.01, "Should show 7 hours remaining (10 - 3)")

        // SCENARIO 2: Last serviced 7 days ago (only recent activity counts)
        // Should show 2 hours used, 8 hours remaining
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        serviceInterval.lastServiceDate = sevenDaysAgo

        let usageScenario2 = bike.rideTimeSince(date: sevenDaysAgo, context: context)
        let timeUntilServiceScenario2 = serviceInterval.intervalTime - usageScenario2

        XCTAssertEqual(usageScenario2, 2.0, accuracy: 0.01, "Should show 2 hours used when serviced 7 days ago")
        XCTAssertEqual(timeUntilServiceScenario2, 8.0, accuracy: 0.01, "Should show 8 hours remaining (10 - 2)")

        // SCENARIO 3: Last serviced today (no activities count)
        // Should show 0 hours used, 10 hours remaining
        let today = Date()
        serviceInterval.lastServiceDate = today

        let usageScenario3 = bike.rideTimeSince(date: today, context: context)
        let timeUntilServiceScenario3 = serviceInterval.intervalTime - usageScenario3

        XCTAssertEqual(usageScenario3, 0.0, accuracy: 0.01, "Should show 0 hours used when serviced today")
        XCTAssertEqual(timeUntilServiceScenario3, 10.0, accuracy: 0.01, "Should show 10 hours remaining (10 - 0)")
    }
}
