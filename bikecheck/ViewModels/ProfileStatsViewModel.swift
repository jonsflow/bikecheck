import Foundation
import CoreData

class ProfileStatsViewModel: ObservableObject {
    @Published var bikeCount: Int = 0
    @Published var totalMiles: Double = 0
    @Published var totalHours: Double = 0
    @Published var activityCount: Int = 0
    @Published var partsTracked: Int = 0
    @Published var overdueCount: Int = 0
    @Published var servicesLogged: Int = 0

    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext

    func load() {
        let bikes = dataService.fetchBikes()
        bikeCount = bikes.count
        totalMiles = bikes.reduce(0.0) { $0 + $1.distance } * 0.000621371
        totalHours = bikes.reduce(0.0) { $0 + $1.rideTime(context: context) }

        activityCount = dataService.fetchActivities().count

        let intervals = dataService.fetchServiceIntervals()
        partsTracked = intervals.count
        servicesLogged = dataService.countAllServiceRecords()
        overdueCount = intervals.filter { interval in
            guard let bike = interval.getBike(from: context) else { return false }
            let ridden = bike.rideTimeSince(date: interval.lastServiceDate ?? Date(), context: context)
            return interval.intervalTime - ridden <= 0
        }.count
    }
}
