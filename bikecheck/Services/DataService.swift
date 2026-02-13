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
    
    func createDefaultServiceIntervals(
        for bike: Bike,
        lastServiceDate: Date = Date(),
        templateIds: [String]? = nil
    ) {
        let templateService = PartTemplateService.shared

        // Use provided templateIds or fall back to default MTB components
        let ids = templateIds ?? ["chain", "fork_lowers", "rear_shock"]

        for templateId in ids {
            guard let template = templateService.getTemplate(id: templateId) else {
                print("Warning: Template '\(templateId)' not found, skipping")
                continue
            }

            let newInterval = ServiceInterval(context: context)
            newInterval.part = template.name
            newInterval.intervalTime = template.defaultIntervalHours
            newInterval.lastServiceDate = lastServiceDate
            newInterval.bikeId = bike.id
            newInterval.notify = template.notifyDefault
        }

        saveContext()
    }
    
    func deleteBike(_ bike: Bike) {
        context.delete(bike)
        saveContext()
    }
}