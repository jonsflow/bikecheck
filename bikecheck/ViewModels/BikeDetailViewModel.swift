import Foundation
import Combine
import CoreData
import SwiftUI

class BikeDetailViewModel: ObservableObject {
    @Published var bike: Bike
    @Published var showingConfirmationDialog = false
    @Published var showingServiceIntervalsCreatedAlert = false
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init(bike: Bike) {
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
        guard let intervals = bike.serviceIntervals else { return }

        for interval in intervals {
            interval.lastServiceDate = date
        }

        dataService.saveContext()
    }
}