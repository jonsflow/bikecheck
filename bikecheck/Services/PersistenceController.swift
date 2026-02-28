import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private(set) var isUsingiCloud: Bool = false

    init(inMemory: Bool = false) {
        // Always use NSPersistentCloudKitContainer even if iCloud is disabled
        container = NSPersistentCloudKitContainer(name: "bikecheck")

        if inMemory {
            // In-memory store for testing
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            // Two-store architecture
            let storeDirectory = container.persistentStoreDescriptions.first!.url!.deletingLastPathComponent()

            // Store 1: Strava Data (ALWAYS local-only, with constraints)
            let stravaStoreURL = storeDirectory.appendingPathComponent("strava.sqlite")
            let stravaStore = NSPersistentStoreDescription(url: stravaStoreURL)
            stravaStore.configuration = "Strava"
            stravaStore.cloudKitContainerOptions = nil // Never sync to iCloud

            // Enable automatic lightweight migration for Strava store
            stravaStore.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            stravaStore.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

            // Store 2: User Data (local + optional CloudKit sync, no constraints)
            let userStoreURL = storeDirectory.appendingPathComponent("userdata.sqlite")
            let userStore = NSPersistentStoreDescription(url: userStoreURL)
            userStore.configuration = "UserData"

            // Enable automatic lightweight migration for UserData store
            userStore.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            userStore.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

            // Check iCloud availability
            isUsingiCloud = checkiCloudAvailability()

            if isUsingiCloud {
                // Enable CloudKit sync for user data only
                userStore.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.com.ride.bikecheck"
                )
                print("iCloud sync enabled for UserData store")
            } else {
                // Just local, no sync
                userStore.cloudKitContainerOptions = nil
                print("iCloud sync disabled - using local storage only")
            }

            container.persistentStoreDescriptions = [stravaStore, userStore]
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("Loaded persistent store: \(storeDescription)")
        })

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private func checkiCloudAvailability() -> Bool {
        // Not signed into iCloud
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud unavailable: User not signed in")
            return false
        }

        // Disable in simulator for easier testing
        #if targetEnvironment(simulator)
        print("iCloud disabled: Running in simulator")
        return false
        #endif

        // Could add user preference here in the future
        // return UserDefaults.standard.bool(forKey: "enableiCloudSync")

        return true
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
        let serviceRecordRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ServiceRecord")
        let athleteRequest: NSFetchRequest<NSFetchRequestResult> = Athlete.fetchRequest()
        let tokenRequest: NSFetchRequest<NSFetchRequestResult> = TokenInfo.fetchRequest()

        // Create batch delete requests
        let bikesDelete = NSBatchDeleteRequest(fetchRequest: bikeRequest)
        let activitiesDelete = NSBatchDeleteRequest(fetchRequest: activityRequest)
        let serviceIntervalsDelete = NSBatchDeleteRequest(fetchRequest: serviceIntervalRequest)
        let serviceRecordsDelete = NSBatchDeleteRequest(fetchRequest: serviceRecordRequest)
        let athleteDelete = NSBatchDeleteRequest(fetchRequest: athleteRequest)
        let tokenDelete = NSBatchDeleteRequest(fetchRequest: tokenRequest)

        do {
            // Execute batch deletes
            try context.execute(serviceRecordsDelete)
            try context.execute(serviceIntervalsDelete)
            try context.execute(activitiesDelete)
            try context.execute(bikesDelete)
            try context.execute(athleteDelete)
            try context.execute(tokenDelete)
            
            // Save context
            try context.save()
            
            // Reset UserDefaults
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

            // Clear Keychain flag so onboarding appears again
            KeychainHelper.shared.clearHasUsedApp()

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