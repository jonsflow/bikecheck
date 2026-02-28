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
    @Published var showUnsavedChangesAlert = false
    @Published var lastServiceDate: Date = Date()
    @Published var selectedTemplate: PartTemplate?
    @Published var serviceRecords: [ServiceRecord] = []

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
        selectedBike = serviceInterval.getBike(from: context)
        if let templateId = serviceInterval.templateId {
            selectedTemplate = PartTemplateService.shared.getTemplate(id: templateId)
        } else {
            selectedTemplate = PartTemplateService.shared.getAllTemplates().first { $0.name == serviceInterval.part }
        }

        // Load the saved last service date, or default to today if not set
        lastServiceDate = serviceInterval.lastServiceDate ?? Date()

        // Store original values for change tracking
        originalPart = part
        originalIntervalTime = intervalTime
        originalNotify = notify
        originalSelectedBike = selectedBike
        originalLastServiceDate = lastServiceDate

        updateTimeUntilService()
        loadServiceRecords()
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

        if !Calendar.current.isDate(lastServiceDate, inSameDayAs: originalLastServiceDate) {
            dataService.createServiceRecord(for: interval, date: lastServiceDate, note: nil, isReset: true)
        }

        if let selectedBike = selectedBike {
            interval.bikeId = selectedBike.id
        }

        dataService.saveContext()
    }

    private func createNewInterval() {
        guard let selectedBike = selectedBike else { return }

        let newInterval = ServiceInterval(context: context)
        newInterval.part = part
        newInterval.templateId = selectedTemplate?.id
        newInterval.intervalTime = Double(intervalTime) ?? 0
        newInterval.notify = notify
        newInterval.lastServiceDate = lastServiceDate
        newInterval.bikeId = selectedBike.id

        dataService.saveContext()
    }

    func resetInterval(note: String?, date: Date) {
        guard let serviceInterval = serviceInterval else { return }

        serviceInterval.lastServiceDate = date
        lastServiceDate = date
        originalLastServiceDate = date
        timeUntilServiceText = String(format: "%.1f", serviceInterval.intervalTime)

        dataService.createServiceRecord(for: serviceInterval, date: date, note: note, isReset: true)
        loadServiceRecords()
    }

    func addNote(note: String, date: Date) {
        guard let serviceInterval = serviceInterval else { return }
        dataService.createServiceRecord(for: serviceInterval, date: date, note: note, isReset: false)
        loadServiceRecords()
    }

    func loadServiceRecords() {
        guard let serviceInterval = serviceInterval else { return }
        serviceRecords = dataService.fetchServiceRecords(for: serviceInterval)
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

    func applyTemplate() {
        guard let template = selectedTemplate else {
            part = ""
            intervalTime = ""
            notify = false
            return
        }

        part = template.name
        intervalTime = String(format: "%.0f", template.defaultIntervalHours)
        notify = template.notifyDefault
    }
}
