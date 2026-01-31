# iCloud Sync Architecture for BikeCheck

**Status:** Planned for future implementation
**Last Updated:** January 29, 2026

## Problem Statement

BikeCheck uses Core Data with uniqueness constraints on Strava-synced entities:
- `Activity.id` (Strava activity ID)
- `Athlete.id` (Strava athlete ID)
- `Bike.id` (Strava gear ID)

**NSPersistentCloudKitContainer does NOT support uniqueness constraints:**
- In iOS 14+, it explicitly errors if entities have constraints
- CloudKit has no concept of unique constraints
- Two devices fetching from Strava independently would create duplicates

**Without constraints:** Every Strava sync would create duplicate activities, bikes, and athletes.

**Conclusion:** We cannot use NSPersistentCloudKitContainer with our current single-store architecture.

## Proposed Solution: Two-Store Architecture

### Core Insight

The **only data users create** is ServiceIntervals. All other data (Activity, Athlete, Bike) comes from Strava and can be re-fetched at any time.

**Solution:** Separate Strava data from user data into two distinct stores.

### Architecture Overview

```
┌─────────────────────────────────────────────┐
│         BikeCheck App                       │
├─────────────────────────────────────────────┤
│                                             │
│  ┌────────────────┐    ┌─────────────────┐ │
│  │  Store 1:      │    │  Store 2:       │ │
│  │  Strava Data   │    │  User Data      │ │
│  │  (Local Only)  │    │  (Local + iCloud)│ │
│  ├────────────────┤    ├─────────────────┤ │
│  │ • Activity     │    │ • ServiceInterval│ │
│  │ • Athlete      │    │                 │ │
│  │ • Bike         │    │                 │ │
│  │ • TokenInfo    │    │                 │ │
│  │                │    │                 │ │
│  │ [Constraints:  │    │ [No Constraints]│ │
│  │  ✓ Enabled]    │    │                 │ │
│  └────────────────┘    └─────────────────┘ │
│         │                      │            │
│         │                      │            │
│         ▼                      ▼            │
│    SQLite File 1          SQLite File 2    │
│    (strava.sqlite)        (userdata.sqlite)│
│                                  │          │
│                                  │          │
│                                  ▼          │
│                          ┌──────────────┐  │
│                          │   iCloud     │  │
│                          │  (Optional)  │  │
│                          └──────────────┘  │
└─────────────────────────────────────────────┘
```

### How It Works

1. **ServiceInterval references Bike by ID (String)**
   - Current: `ServiceInterval.bike` (relationship)
   - New: `ServiceInterval.bikeId` (String attribute containing Strava gear ID)

2. **Cross-store lookups**
   ```swift
   extension ServiceInterval {
       func getBike(from context: NSManagedObjectContext) -> Bike? {
           let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "id == %@", bikeId)
           return try? context.fetch(fetchRequest).first
       }
   }
   ```

3. **Sync flow**
   - Device A: User creates ServiceInterval for Bike "b12345"
   - iCloud: ServiceInterval syncs to Device B
   - Device B: Receives ServiceInterval, looks up Bike "b12345" in local store
   - If Bike doesn't exist: Fetch from Strava API

## Implementation Details

### Core Data Model Changes

**ServiceInterval Entity:**
```
REMOVE:
- relationship: bike → Bike

ADD:
- attribute: bikeId (String, non-optional)
```

**Core Data Configurations:**
```
Configuration "Strava":
  - Activity
  - Athlete
  - Bike
  - TokenInfo

Configuration "UserData":
  - ServiceInterval
```

### PersistenceController Implementation

```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    private(set) var isUsingiCloud: Bool = false

    init(inMemory: Bool = false) {
        // Always use CloudKit container
        container = NSPersistentCloudKitContainer(name: "bikecheck")

        let storeDirectory = // ... app support directory

        // Store 1: Strava Data (ALWAYS local-only)
        let stravaStoreURL = storeDirectory.appendingPathComponent("strava.sqlite")
        let stravaStore = NSPersistentStoreDescription(url: stravaStoreURL)
        stravaStore.configuration = "Strava"
        stravaStore.cloudKitContainerOptions = nil // Never sync

        // Store 2: User Data (local + optional CloudKit sync)
        let userStoreURL = storeDirectory.appendingPathComponent("userdata.sqlite")
        let userStore = NSPersistentStoreDescription(url: userStoreURL)
        userStore.configuration = "UserData"

        // Check iCloud availability
        isUsingiCloud = checkiCloudAvailability()

        if isUsingiCloud {
            // Enable CloudKit sync for user data only
            userStore.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.yourapp.bikecheck"
            )
        } else {
            // Just local, no sync
            userStore.cloudKitContainerOptions = nil
        }

        container.persistentStoreDescriptions = [stravaStore, userStore]

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        // Auto-merge from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    private func checkiCloudAvailability() -> Bool {
        // Not signed into iCloud
        guard FileManager.default.ubiquityIdentityToken != nil else {
            return false
        }

        // Disable in simulator for easier testing
        #if targetEnvironment(simulator)
        return false
        #endif

        // Could add user preference here
        // return UserDefaults.standard.bool(forKey: "enableiCloudSync")

        return true
    }
}
```

### Code Refactoring Required

**Everywhere you currently access `serviceInterval.bike`:**

**Before:**
```swift
let bikeName = serviceInterval.bike.name
let rideTime = serviceInterval.bike.rideTime(context: context)
```

**After:**
```swift
guard let bike = serviceInterval.getBike(from: context) else {
    // Handle missing bike - maybe fetch from Strava
    return
}
let bikeName = bike.name
let rideTime = bike.rideTime(context: context)
```

**Files likely needing updates:**
- `ServiceViewModel.swift`
- `ServiceView.swift`
- `BikeDetailView.swift`
- `AddServiceIntervalViewModel.swift`
- `NotificationService.swift`
- Any other views/view models accessing service intervals

### Migration Strategy

**For existing users:**

1. Create new `bikeId` attribute on ServiceInterval
2. Migrate existing data:
   ```swift
   // One-time migration on app launch
   let intervals = dataService.fetchServiceIntervals()
   for interval in intervals {
       if interval.bikeId == nil, let bike = interval.bike {
           interval.bikeId = bike.id
       }
   }
   dataService.saveContext()
   ```
3. Remove `bike` relationship in next model version

## Edge Cases & Solutions

### Case 1: ServiceInterval references deleted Bike

**Scenario:** User deletes bike on Device A before ServiceInterval syncs to Device B

**Solution:**
```swift
extension ServiceInterval {
    func getBike(from context: NSManagedObjectContext) -> Bike? {
        if let bike = fetchLocalBike(from: context) {
            return bike
        }

        // Bike not found locally, try fetching from Strava
        StravaService.shared.fetchBike(withId: bikeId) { result in
            // Handle async bike fetch
        }

        return nil
    }
}
```

### Case 2: iCloud quota exceeded

**Solution:** Monitor CloudKit errors and notify user
```swift
func persistentStore(_ store: NSPersistentStore,
                     didChange eventType: NSPersistentStoreRemoteChange) {
    // Check for quota errors
    // Show user-friendly message
}
```

### Case 3: User switches iCloud account

**Solution:** ServiceIntervals are local first, so they persist. On next Strava sync, bikes will be re-fetched.

## Benefits

✅ **Keeps constraints** - Strava data integrity maintained
✅ **Simple sync** - Only ServiceIntervals sync (simple entity, no nested relationships)
✅ **No deduplication needed** - Each store handles its own data
✅ **Graceful degradation** - Works without iCloud
✅ **Testing friendly** - Disable CloudKit in tests/simulator
✅ **Low risk** - Strava data can always be re-fetched
✅ **User control** - Can toggle iCloud sync on/off

## Trade-offs

⚠️ **Cross-store relationships** - ServiceInterval → Bike requires manual lookup
⚠️ **Code complexity** - Need helper methods for cross-store access
⚠️ **Migration required** - Existing users need data migration
⚠️ **Testing** - Need to test both iCloud and non-iCloud modes

## Testing Strategy

### Local Testing (Simulator)
- iCloud automatically disabled
- Both stores exist locally
- Test all CRUD operations on ServiceIntervals

### iCloud Testing (Physical Devices)
- Requires 2+ physical devices with same Apple ID
- Test scenarios:
  - Create ServiceInterval on Device A → verify on Device B
  - Create Bike on Device A → create ServiceInterval → verify on Device B
  - Delete Bike on Device A → verify ServiceInterval handling on Device B
  - Sign out of iCloud → verify app still functions
  - Exceed iCloud quota → verify error handling

### Unit Tests
```swift
func testServiceIntervalBikeLookup() {
    let bike = createTestBike(id: "test123")
    let interval = createTestServiceInterval(bikeId: "test123")

    XCTAssertEqual(interval.getBike(from: context)?.id, "test123")
}

func testMissingBikeHandling() {
    let interval = createTestServiceInterval(bikeId: "missing")

    XCTAssertNil(interval.getBike(from: context))
    // Verify graceful handling
}
```

## Future Enhancements

### Phase 1 (Initial Implementation)
- Two-store setup with optional iCloud sync
- ServiceInterval.bikeId implementation
- Basic cross-store lookup
- Migration for existing users

### Phase 2 (Reliability)
- Robust error handling for quota/network issues
- User preference to enable/disable iCloud sync
- Conflict resolution strategies
- Background sync monitoring

### Phase 3 (Advanced)
- Share ServiceIntervals between users (CloudKit sharing)
- Backup/restore functionality
- Export to JSON for manual transfer

## Implementation Checklist

- [ ] Create new Core Data model version
- [ ] Add "Strava" and "UserData" configurations
- [ ] Add `bikeId` attribute to ServiceInterval
- [ ] Update PersistenceController with two-store setup
- [ ] Implement `ServiceInterval.getBike(from:)` helper
- [ ] Refactor all code accessing `serviceInterval.bike`
- [ ] Add iCloud capability in Xcode
- [ ] Implement migration for existing users
- [ ] Add iCloud status monitoring
- [ ] Update UI to show sync status
- [ ] Write unit tests for cross-store access
- [ ] Test on physical devices with iCloud
- [ ] Document iCloud setup in README
- [ ] Update onboarding to explain sync (optional)

## References

- [Apple: Mirroring Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring-a-core-data-store-with-cloudkit)
- [Apple: NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [Constraints incompatibility discussion](https://developer.apple.com/forums/thread/656380)
- [General findings about NSPersistentCloudKitContainer](https://crunchybagel.com/nspersistentcloudkitcontainer/)

## Notes

- This approach was chosen after investigating direct SQLite file sync to iCloud Drive (deprecated in iOS 10)
- NSPersistentCloudKitContainer is Apple's recommended approach as of iOS 13+
- The two-store architecture is necessary because CloudKit doesn't support uniqueness constraints
- Strava data integrity is prioritized over sync complexity
