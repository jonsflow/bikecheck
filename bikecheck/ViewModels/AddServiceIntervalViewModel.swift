import Foundation
import CoreData
import Combine

class AddServiceIntervalViewModel: ObservableObject {
    @Published var part = ""
    @Published var intervalTime = ""
    @Published var notify = false
    @Published var selectedBike: Bike?
    @Published var bikes: [Bike] = []
    @Published var timeUntilServiceText: String = ""
    @Published var deleteConfirmationDialog = false
    @Published var resetConfirmationDialog = false
    @Published var showUnsavedChangesAlert = false
    @Published var lastServiceDate: Date = Date()
    
    // Original values for tracking changes
    private var originalPart = ""
    private var originalIntervalTime = ""
    private var originalNotify = false
    private var originalSelectedBike: Bike?
    private var originalLastServiceDate: Date = Date()
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    var serviceInterval: ServiceInterval?
    
    init(serviceInterval: ServiceInterval? = nil) {
        self.serviceInterval = serviceInterval
        loadBikes()
        if let serviceInterval = serviceInterval {
            loadServiceIntervalData(serviceInterval)
        }
    }
    
    func loadBikes() {
        bikes = dataService.fetchBikes()
        if selectedBike == nil && !bikes.isEmpty {
            selectedBike = bikes.first
        }
    }
    
    private func loadServiceIntervalData(_ serviceInterval: ServiceInterval) {
        part = serviceInterval.part
        intervalTime = String(format: "%.1f", serviceInterval.intervalTime)
        notify = serviceInterval.notify
        selectedBike = serviceInterval.bike

        // Load the saved last service date, or default to today if not set
        lastServiceDate = serviceInterval.lastServiceDate ?? Date()

        // Store original values for change tracking
        originalPart = part
        originalIntervalTime = intervalTime
        originalNotify = notify
        originalSelectedBike = selectedBike
        originalLastServiceDate = lastServiceDate

        updateTimeUntilService()
    }
    
    var hasUnsavedChanges: Bool {
        guard serviceInterval != nil else {
            return false // Not in edit mode
        }

        return part != originalPart ||
               intervalTime != originalIntervalTime ||
               notify != originalNotify ||
               selectedBike != originalSelectedBike ||
               !Calendar.current.isDate(lastServiceDate, inSameDayAs: originalLastServiceDate)
    }
    
    func updateTimeUntilService() {
        guard let serviceInterval = serviceInterval, let selectedBike = selectedBike else { return }

        // Calculate ride time since the last service date
        let rideTimeSinceService = selectedBike.rideTimeSince(date: lastServiceDate, context: context)
        let timeUntilService = serviceInterval.intervalTime - rideTimeSinceService

        timeUntilServiceText = String(format: "%.1f", timeUntilService)
    }
    
    func saveServiceInterval() {
        if let existingInterval = serviceInterval {
            updateExistingInterval(existingInterval)
        } else {
            createNewInterval()
        }
    }
    
    private func updateExistingInterval(_ interval: ServiceInterval) {
        interval.part = part
        interval.intervalTime = Double(intervalTime) ?? 0
        interval.notify = notify
        interval.lastServiceDate = lastServiceDate

        if let selectedBike = selectedBike {
            interval.bike = selectedBike
        }

        dataService.saveContext()
    }
    
    private func createNewInterval() {
        guard let selectedBike = selectedBike else { return }

        let newInterval = ServiceInterval(context: context)
        newInterval.part = part
        newInterval.intervalTime = Double(intervalTime) ?? 0
        newInterval.notify = notify
        newInterval.lastServiceDate = lastServiceDate
        newInterval.bike = selectedBike

        dataService.saveContext()
    }
    
    func resetInterval() {
        guard let serviceInterval = serviceInterval else { return }

        // Reset to today's date
        lastServiceDate = Date()
        serviceInterval.lastServiceDate = lastServiceDate
        timeUntilServiceText = String(format: "%.1f", serviceInterval.intervalTime)

        dataService.saveContext()
    }
    
    func deleteInterval() {
        guard let serviceInterval = serviceInterval else { return }
        
        context.delete(serviceInterval)
        dataService.saveContext()
    }
    
    func checkForChangesBeforeDismiss(completion: @escaping (Bool) -> Void) {
        if hasUnsavedChanges {
            showUnsavedChangesAlert = true
            completion(false) // Don't dismiss yet
        } else {
            completion(true) // Allow dismissal
        }
    }
}

