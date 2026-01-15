import CoreData
import os.log

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    private let logger = Logger(subsystem: "com.bikecheck", category: "CloudKit")

    private var hasCompletedInitialImport = false

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "bikecheck")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            // Disable CloudKit for in-memory stores (testing)
            container.persistentStoreDescriptions.first!.cloudKitContainerOptions = nil
        } else {
            // Enable automatic lightweight migration
            container.persistentStoreDescriptions.first?.setOption(
                true as NSNumber,
                forKey: NSMigratePersistentStoresAutomaticallyOption
            )
            container.persistentStoreDescriptions.first?.setOption(
                true as NSNumber,
                forKey: NSInferMappingModelAutomaticallyOption
            )
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.logger.info("Persistent store loaded: \(storeDescription)")

            // Check if this is first launch by checking for existing data
            let context = self.container.viewContext
            let bikeRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Bike")
            bikeRequest.fetchLimit = 1

            do {
                let count = try context.count(for: bikeRequest)
                if count > 0 {
                    // Already have local data - no need to wait for CloudKit
                    self.logger.info("Local data exists - skipping CloudKit wait")
                    self.hasCompletedInitialImport = true
                    DispatchQueue.main.async {
                        StravaService.shared.checkAuthenticationAfterStoreLoad()
                    }
                } else {
                    // No local data - wait for potential CloudKit import (first launch scenario)
                    self.logger.info("No local data - waiting for CloudKit import")
                    self.scheduleCloudKitTimeout()
                }
            } catch {
                self.logger.error("Error checking for local data: \(error.localizedDescription)")
                // On error, proceed with timeout
                self.scheduleCloudKitTimeout()
            }
        })

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Listen for CloudKit sync notifications
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { [weak self] notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                self?.logger.info("CloudKit event: \(event.type.rawValue) - succeeded: \(event.succeeded) - endDate: \(String(describing: event.endDate))")
                if let error = event.error {
                    self?.logger.error("CloudKit error: \(error.localizedDescription)")
                }

                // Wait for first COMPLETED import event (endDate != nil means finished)
                if event.type == .import && event.endDate != nil && self?.hasCompletedInitialImport == false {
                    self?.hasCompletedInitialImport = true
                    self?.logger.info("CloudKit import completed - checking auth")
                    DispatchQueue.main.async {
                        StravaService.shared.checkAuthenticationAfterStoreLoad()
                    }
                }
            }
        }
    }

    private func scheduleCloudKitTimeout() {
        // Timeout fallback: if no CloudKit import completes within 5 seconds, proceed anyway
        // This handles cases where CloudKit is not available (simulator, user not signed in, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if !self.hasCompletedInitialImport {
                self.hasCompletedInitialImport = true
                self.logger.info("CloudKit import timeout - proceeding to check auth")
                StravaService.shared.checkAuthenticationAfterStoreLoad()
            }
        }
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func resetAllData() {
        let context = container.viewContext
        
        // Create fetch requests for all entities
        let bikeRequest: NSFetchRequest<NSFetchRequestResult> = Bike.fetchRequest()
        let activityRequest: NSFetchRequest<NSFetchRequestResult> = Activity.fetchRequest()
        let serviceIntervalRequest: NSFetchRequest<NSFetchRequestResult> = ServiceInterval.fetchRequest()
        let athleteRequest: NSFetchRequest<NSFetchRequestResult> = Athlete.fetchRequest()
        let tokenRequest: NSFetchRequest<NSFetchRequestResult> = TokenInfo.fetchRequest()
        
        // Create batch delete requests
        let bikesDelete = NSBatchDeleteRequest(fetchRequest: bikeRequest)
        let activitiesDelete = NSBatchDeleteRequest(fetchRequest: activityRequest)
        let serviceIntervalsDelete = NSBatchDeleteRequest(fetchRequest: serviceIntervalRequest)
        let athleteDelete = NSBatchDeleteRequest(fetchRequest: athleteRequest)
        let tokenDelete = NSBatchDeleteRequest(fetchRequest: tokenRequest)
        
        do {
            // Execute batch deletes
            try context.execute(serviceIntervalsDelete)
            try context.execute(activitiesDelete)
            try context.execute(bikesDelete)
            try context.execute(athleteDelete)
            try context.execute(tokenDelete)
            
            // Save context
            try context.save()
            
            // Reset UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            // Reset StravaService state on main queue
            DispatchQueue.main.async {
                let stravaService = StravaService.shared
                stravaService.isSignedIn = false
                stravaService.tokenInfo = nil
                stravaService.athlete = nil
                stravaService.bikes = nil
                stravaService.activities = nil
                stravaService.profileImage = nil
            }
            
            print("Successfully reset all app data")
            
        } catch {
            print("Failed to reset app data: \(error)")
        }
    }
}