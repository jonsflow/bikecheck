import Foundation
import Combine
import CoreData

class ServiceViewModel: ObservableObject {
    @Published var serviceIntervals: [ServiceInterval] = []
    @Published var isLoading = false
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
        setupCloudKitObservers()
    }

    private func setupCloudKitObservers() {
        // Listen for CloudKit import notifications
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                print("CloudKit remote change detected, reloading service intervals")
                DispatchQueue.main.async {
                    self?.loadServiceIntervals()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadServiceIntervals() {
        isLoading = true
        serviceIntervals = dataService.fetchServiceIntervals()
        isLoading = false
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

