import Foundation
import Combine
import CoreData

class ServiceViewModel: ObservableObject {
    @Published var serviceIntervals: [ServiceInterval] = []
    @Published var isLoading = false
    @Published var isWaitingForCloudKit = false
    @Published var error: Error?

    private let dataService = DataService.shared
    private let stravaService = StravaService.shared
    private let context = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()

    var serviceIntervalsByBike: [Bike: [ServiceInterval]] {
        var grouped: [Bike: [ServiceInterval]] = [:]
        for interval in serviceIntervals {
            if let bike = interval.getBike(from: context) {
                grouped[bike, default: []].append(interval)
            }
        }
        return grouped
    }

    init() {
        loadServiceIntervals()
        setupMergeObserver()

        // If CloudKit is enabled and we have no intervals, show loading state
        if PersistenceController.shared.isUsingiCloud && serviceIntervals.isEmpty {
            isWaitingForCloudKit = true
            print("CloudKit enabled with no intervals - showing loading state")

            // Timeout after 60 seconds to prevent infinite loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                if self?.isWaitingForCloudKit == true {
                    print("CloudKit import timeout - hiding loading state")
                    self?.isWaitingForCloudKit = false
                }
            }
        }
    }

    private func setupMergeObserver() {
        // Listen for when viewContext receives merged changes from CloudKit background context
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] notification in
                guard let self = self else { return }

                // Check if ServiceInterval entities were inserted or refreshed (from CloudKit merge)
                let hasIntervalChanges = [NSInsertedObjectsKey, NSRefreshedObjectsKey].contains { key in
                    if let objects = notification.userInfo?[key] as? Set<NSManagedObject> {
                        return objects.contains(where: { $0 is ServiceInterval })
                    }
                    return false
                }

                if hasIntervalChanges {
                    print("ServiceIntervals changed in viewContext - reloading")
                    DispatchQueue.main.async {
                        self.loadServiceIntervals()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadServiceIntervals() {
        isLoading = true
        serviceIntervals = dataService.fetchServiceIntervals()
        isLoading = false

        // If we got intervals, we're no longer waiting for CloudKit
        if !serviceIntervals.isEmpty && isWaitingForCloudKit {
            print("ServiceIntervals loaded from CloudKit - hiding loading state")
            isWaitingForCloudKit = false
        }
    }
    
    func calculateTimeUntilService(for serviceInterval: ServiceInterval) -> Double {
        return stravaService.calculateTimeUntilService(for: serviceInterval)
    }
    
    func getTimeUntilServiceText(for serviceInterval: ServiceInterval) -> String {
        let timeUntilService = calculateTimeUntilService(for: serviceInterval)
        return String(format: "%.2f", timeUntilService)
    }
    
    func deleteInterval(serviceInterval: ServiceInterval) {
        context.delete(serviceInterval)
        dataService.saveContext()
        loadServiceIntervals()
    }
    
    func resetInterval(serviceInterval: ServiceInterval) {
        serviceInterval.lastServiceDate = Date()
        dataService.saveContext()
    }
}

