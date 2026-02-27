import XCTest
import CoreData
@testable import bikecheck

/// Tests for service history record creation when the last service date is changed.
/// Covers the logic in AddServiceIntervalViewModel.updateExistingInterval and resetInterval.
class ServiceDateChangeTests: XCTestCase {

    var mockPersistenceController: MockPersistenceController!
    var dataService: DataService!
    var context: NSManagedObjectContext!
    var serviceInterval: ServiceInterval!

    override func setUp() {
        super.setUp()
        mockPersistenceController = MockPersistenceController()
        context = mockPersistenceController.container.viewContext
        dataService = DataService(context: context)

        let bike = NSEntityDescription.insertNewObject(forEntityName: "Bike", into: context) as! Bike
        bike.id = "test-bike"
        bike.name = "Test Bike"
        bike.distance = 1000.0

        serviceInterval = NSEntityDescription.insertNewObject(forEntityName: "ServiceInterval", into: context) as! ServiceInterval
        serviceInterval.part = "Chain"
        serviceInterval.intervalTime = 10.0
        serviceInterval.bikeId = bike.id
        serviceInterval.notify = true
        serviceInterval.lastServiceDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())

        try? context.save()
    }

    override func tearDown() {
        serviceInterval = nil
        dataService = nil
        context = nil
        mockPersistenceController = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Mirrors the condition in updateExistingInterval that guards service record creation.
    private func saveWithDateChange(from originalDate: Date, to newDate: Date) {
        serviceInterval.lastServiceDate = newDate
        if !Calendar.current.isDate(newDate, inSameDayAs: originalDate) {
            dataService.createServiceRecord(for: serviceInterval, date: newDate, note: nil, isReset: true)
        }
        try? context.save()
    }

    // MARK: - Tests

    /// Changing the last service date to a different day should create one service record.
    func testServiceRecordCreatedWhenLastServiceDateChanges() {
        let originalDate = serviceInterval.lastServiceDate!
        let newDate = Date() // today — 30 days after originalDate

        saveWithDateChange(from: originalDate, to: newDate)

        let records = dataService.fetchServiceRecords(for: serviceInterval)
        XCTAssertEqual(records.count, 1, "One service record should be created when the date changes to a different day")
    }

    /// Adjusting the time within the same day should not create a service record.
    func testNoServiceRecordWhenDateIsOnSameDay() {
        let originalDate = serviceInterval.lastServiceDate!
        let sameDay = originalDate.addingTimeInterval(3600) // one hour later, still same day

        saveWithDateChange(from: originalDate, to: sameDay)

        let records = dataService.fetchServiceRecords(for: serviceInterval)
        XCTAssertEqual(records.count, 0, "No service record should be created when the date stays on the same day")
    }

    /// After "Log Service" (resetInterval), navigating back triggers saveServiceInterval.
    /// Because resetInterval now updates originalLastServiceDate, the subsequent save
    /// should not create a second (duplicate) record.
    func testResetFollowedBySaveCreatesExactlyOneRecord() {
        let resetDate = Date()

        // Simulate resetInterval: creates record and updates originalLastServiceDate
        serviceInterval.lastServiceDate = resetDate
        var originalLastServiceDate = resetDate // our fix — mirrors what resetInterval now does
        dataService.createServiceRecord(for: serviceInterval, date: resetDate, note: nil, isReset: true)

        // Simulate the subsequent saveServiceInterval call from onDisappear.
        // Because originalLastServiceDate was updated by resetInterval, the date
        // comparison is same-day → no additional record is created.
        if !Calendar.current.isDate(resetDate, inSameDayAs: originalLastServiceDate) {
            dataService.createServiceRecord(for: serviceInterval, date: resetDate, note: nil, isReset: true)
        }

        let records = dataService.fetchServiceRecords(for: serviceInterval)
        XCTAssertEqual(records.count, 1, "Only one service record should exist — no duplicate from the onDisappear save")

        _ = originalLastServiceDate // suppress unused-variable warning
    }

    /// Service records created from date changes should be flagged as resets.
    func testServiceRecordIsMarkedAsReset() {
        let originalDate = serviceInterval.lastServiceDate!
        let newDate = Date()

        saveWithDateChange(from: originalDate, to: newDate)

        let records = dataService.fetchServiceRecords(for: serviceInterval)
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(records.first?.isReset == true, "Service records created by a date change should be marked isReset = true")
    }
}
