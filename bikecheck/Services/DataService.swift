import Foundation
import CoreData

class DataService {
    static let shared = DataService()
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchBikes() -> [Bike] {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Bike.name, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch bikes: \(error)")
            return []
        }
    }
    
    func fetchActivities() -> [Activity] {
        let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest() as! NSFetchRequest<Activity>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "type == %@", "Ride")
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch activities: \(error)")
            return []
        }
    }
    
    func fetchServiceIntervals() -> [ServiceInterval] {
        let fetchRequest: NSFetchRequest<ServiceInterval> = ServiceInterval.fetchRequest() as! NSFetchRequest<ServiceInterval>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceInterval.lastServiceDate, ascending: false)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch service intervals: \(error)")
            return []
        }
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func createDefaultServiceIntervals(for bike: Bike, lastServiceDate: Date = Date()) {
        let newServInt1 = ServiceInterval(context: context)
        let newServInt2 = ServiceInterval(context: context)
        let newServInt3 = ServiceInterval(context: context)

        newServInt2.intervalTime = 5
        newServInt2.lastServiceDate = lastServiceDate
        newServInt2.bike = bike
        newServInt2.part = "chain"
        newServInt2.notify = true

        newServInt3.intervalTime = 10
        newServInt3.lastServiceDate = lastServiceDate
        newServInt3.bike = bike
        newServInt3.part = "Fork Lowers"
        newServInt3.notify = true

        newServInt1.intervalTime = 15
        newServInt1.lastServiceDate = lastServiceDate
        newServInt1.bike = bike
        newServInt1.part = "Shock"
        newServInt1.notify = true

        saveContext()
    }
    
    func deleteBike(_ bike: Bike) {
        context.delete(bike)
        saveContext()
    }
}