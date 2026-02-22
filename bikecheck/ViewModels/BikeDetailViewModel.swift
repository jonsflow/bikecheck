import Foundation
import Combine
import CoreData
import SwiftUI

class BikeDetailViewModel: ObservableObject {
    @Published var bike: Bike
    @Published var showingConfirmationDialog = false
    @Published var showingServiceIntervalsCreatedAlert = false
    @Published var showingPresetConfirmation = false
    @Published var detectionResult: BikeDetectionResult?

    private let dataService: DataService
    private let context = PersistenceController.shared.container.viewContext

    init(dataService: DataService = DataService.shared, bike: Bike) {
        self.dataService = dataService
        self.bike = bike
    }
    
    func getTotalRideTime() -> String {
        return String(format: "%.2f", bike.rideTime(context: context))
    }
    
    func getActivityCount() -> Int {
        return bike.activities(context: context).count
    }
    
    func getMileage() -> String {
        return String(format: "%.2f", (bike.distance) * 0.000621371)
    }
    
    func deleteBike() {
        dataService.deleteBike(bike)
    }
    
    func createDefaultServiceIntervals(lastServiceDate: Date = Date()) {
        dataService.createDefaultServiceIntervals(for: bike, lastServiceDate: lastServiceDate)
        showingServiceIntervalsCreatedAlert = true
    }

    func updateAllServiceDates(to date: Date) {
        let intervals = bike.serviceIntervals(from: context)

        guard !intervals.isEmpty else { return }

        for interval in intervals {
            interval.lastServiceDate = date
        }

        dataService.saveContext()
    }

    // MARK: - Bike Detection

    func detectBikeType() {
        let result = BikeDetectionService.shared.detectBike(name: bike.name ?? "")
        detectionResult = result
        showingPresetConfirmation = true
    }

    func createIntervals(templateIds: [String], lastServiceDate: Date) {
        dataService.createDefaultServiceIntervals(
            for: bike,
            lastServiceDate: lastServiceDate,
            templateIds: templateIds
        )
        showingServiceIntervalsCreatedAlert = true
    }
}