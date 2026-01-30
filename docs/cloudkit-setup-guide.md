# CloudKit Setup Guide for BikeCheck

**Status:** Implementation in progress
**Last Updated:** January 30, 2026

## Overview

BikeCheck now uses a **two-store Core Data architecture** that enables CloudKit sync for ServiceIntervals while keeping Strava data local with uniqueness constraints.

## What's Been Implemented ✓

### 1. Code Changes (Completed)
- ✅ Two-store Core Data architecture
- ✅ ServiceInterval uses `bikeId` string for cross-store references
- ✅ Helper methods: `ServiceInterval.getBike(from:)` and `Bike.serviceIntervals(from:)`
- ✅ NSPersistentCloudKitContainer configuration
- ✅ iCloud availability detection
- ✅ Entitlements file created: `bikecheck/bikecheck.entitlements`
- ✅ CloudKit container ID: `iCloud.com.ride.bikecheck`

### 2. Store Configuration

**Strava Store** (Local only, never syncs)
- Entities: Activity, Athlete, Bike, TokenInfo
- File: `strava.sqlite`
- Uniqueness constraints: ✓ Enabled
- CloudKit: ❌ Disabled

**UserData Store** (iCloud-enabled)
- Entities: ServiceInterval
- File: `userdata.sqlite`
- Uniqueness constraints: ❌ None
- CloudKit: ✓ Enabled (when signed into iCloud on device)

### 3. Simulator vs Device Behavior

**Simulator:**
- iCloud sync is **disabled** (code check at `PersistenceController.swift:78`)
- Uses local storage only
- Good for testing without iCloud complications

**Physical Device:**
- iCloud sync **enabled** if user is signed into iCloud
- ServiceIntervals automatically sync via CloudKit
- Data persists across app reinstalls

## Required Manual Steps in Xcode

You must complete these steps in Xcode for CloudKit to work:

### Step 1: Add Entitlements File to Project

1. Open `bikecheck.xcodeproj` in Xcode
2. In Project Navigator, verify `bikecheck.entitlements` is listed under the `bikecheck` folder
3. If not visible:
   - Right-click `bikecheck` folder → **Add Files to "bikecheck"**
   - Select `bikecheck/bikecheck.entitlements`
   - Ensure **"Copy items if needed"** is unchecked
   - Click **Add**

### Step 2: Link Entitlements in Build Settings

1. Select the **bikecheck** project in Project Navigator
2. Select the **bikecheck** target
3. Go to **Build Settings** tab
4. Search for **"Code Signing Entitlements"**
5. Set the value to: `bikecheck/bikecheck.entitlements`

### Step 3: Enable iCloud Capability

1. Select the **bikecheck** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **iCloud**
5. In the iCloud section:
   - ✓ Check **CloudKit**
   - Under **Containers**, click **+** and add:
     - `iCloud.com.ride.bikecheck`
   - Xcode will automatically create the CloudKit container in your Apple Developer account

### Step 4: Verify Configuration

After completing the above:

1. Check **Signing & Capabilities** tab shows:
   ```
   iCloud
   ├── Services
   │   └── ✓ CloudKit
   └── Containers
       └── iCloud.com.ride.bikecheck
   ```

2. Check **Build Settings** shows:
   ```
   Code Signing Entitlements: bikecheck/bikecheck.entitlements
   ```

3. The entitlements file should contain:
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.ride.bikecheck</string>
   </array>
   <key>com.apple.developer.icloud-services</key>
   <array>
       <string>CloudKit</string>
   </array>
   ```

## Testing CloudKit Sync

### Prerequisites
- ✓ Apple Developer account (required for CloudKit)
- ✓ Physical iOS device (CloudKit disabled in simulator)
- ✓ Device signed into iCloud with your Apple ID

### Test Procedure

#### Test 1: Verify iCloud is Enabled
1. Run app on physical device
2. Check console logs for:
   ```
   iCloud sync enabled for UserData store
   Loaded persistent store: <UserData configuration>
   ```
3. If you see "iCloud disabled", check:
   - Device is signed into iCloud (Settings → [Your Name])
   - iCloud Drive is enabled
   - App has iCloud capability enabled

#### Test 2: Create Service Interval
1. Add a bike and create a service interval
2. Wait 5-10 seconds for CloudKit to sync
3. Check CloudKit Dashboard:
   - Go to https://icloud.developer.apple.com/dashboard
   - Select `iCloud.com.ride.bikecheck` container
   - Go to **Data** → **Default Zone**
   - You should see `CD_ServiceInterval` records

#### Test 3: Data Persistence Across Reinstalls
1. Create several service intervals on Device 1
2. Wait for sync (check console for CloudKit activity)
3. Delete the app from Device 1
4. Reinstall and open the app
5. **Expected:** Service intervals are restored from iCloud
6. **Note:** You'll need to re-authenticate with Strava (bikes will be re-imported)

#### Test 4: Multi-Device Sync (Optional)
1. Install app on Device 2 with same Apple ID
2. Sign into Strava
3. Create service intervals on Device 2
4. Wait for sync
5. Check Device 1 - should see new intervals appear

### Troubleshooting

**Problem:** Console shows "iCloud disabled: Running in simulator"
- **Solution:** Use a physical device; CloudKit doesn't work in simulator

**Problem:** Console shows "iCloud unavailable: User not signed in"
- **Solution:** Sign into iCloud on the device (Settings → [Your Name])

**Problem:** Service intervals don't sync
- **Solution:**
  1. Check CloudKit Dashboard for errors
  2. Verify entitlements are correctly set in Xcode
  3. Ensure device has internet connection
  4. Check console for CloudKit sync errors

**Problem:** "Failed to initialize CloudKit container"
- **Solution:**
  1. Verify container ID matches: `iCloud.com.ride.bikecheck`
  2. Check Apple Developer account has CloudKit enabled
  3. Rebuild app after changing capabilities

**Problem:** Duplicate service intervals after reinstall
- **Solution:**
  - This shouldn't happen with CloudKit
  - If it does, check that `NSPersistentCloudKitContainer` is being used (not `NSPersistentContainer`)
  - Verify store configuration in `PersistenceController.swift`

## How It Works

### Data Flow

```
User creates ServiceInterval
         ↓
Saved to UserData store (userdata.sqlite)
         ↓
NSPersistentCloudKitContainer detects change
         ↓
Uploads to CloudKit (iCloud.com.ride.bikecheck)
         ↓
Other devices download from CloudKit
         ↓
Merge into local UserData store
```

### What Syncs vs What Doesn't

**✓ Syncs to iCloud:**
- ServiceInterval (part name, interval time, last service date, notifications)

**✗ Stays Local:**
- Bikes (re-imported from Strava)
- Activities (re-imported from Strava)
- Athlete data (re-imported from Strava)
- Strava OAuth tokens (security - never synced)

### App Reinstall Behavior

**Before CloudKit:**
- ❌ All service intervals lost
- ❌ User must recreate from scratch

**After CloudKit:**
- ✓ Service intervals restored from iCloud
- ✓ User re-authenticates with Strava (OAuth security)
- ✓ Bikes re-imported from Strava
- ✓ Activities re-imported from Strava
- ✓ Service intervals automatically match to re-imported bikes (via `bikeId`)

## Production Considerations

### Before App Store Release

1. **Change to Production Environment**
   - Update entitlements: `<key>aps-environment</key>` → `<string>production</string>`

2. **Test CloudKit Schema**
   - Deploy schema from Development to Production in CloudKit Dashboard
   - Test with TestFlight builds

3. **Privacy Policy**
   - Update privacy policy to mention iCloud sync
   - Explain what data is stored in iCloud

4. **User Control**
   - Consider adding Settings toggle to enable/disable iCloud sync
   - Currently at `PersistenceController.swift:84` (commented out)

### CloudKit Quotas

- **Free tier:** 1GB storage per user, 10GB data transfer/day
- **Plenty for BikeCheck:** ServiceIntervals are tiny (~500 bytes each)
- **Typical user:** 10-20 intervals = ~10KB total

### Data Migration

If users already have the app installed:
- New two-store architecture will create new database files
- Old data in single store won't automatically migrate
- Consider migration script or let users recreate intervals (rare scenario)

## Next Steps

1. ✅ Complete Xcode manual setup steps above
2. ✅ Test on physical device
3. ✅ Verify CloudKit Dashboard shows data
4. ✅ Test app reinstall scenario
5. ⏳ Deploy to TestFlight for beta testing
6. ⏳ Update App Store description to mention iCloud sync

## Files Modified

- `bikecheck/Services/PersistenceController.swift` - Two-store configuration
- `bikecheck/Models/ServiceInterval.swift` - Added `bikeId` and `getBike(from:)`
- `bikecheck/Models/Bike.swift` - Added `serviceIntervals(from:)`
- `bikecheck/bikecheck.entitlements` - iCloud and CloudKit capabilities
- `bikecheck.xcdatamodeld/bikecheck.xcdatamodel/contents` - Store configurations
- All ViewModels and Views - Updated to use cross-store helper methods
- All test files - Updated for two-store architecture

## References

- [NSPersistentCloudKitContainer Documentation](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CloudKit Quick Start](https://developer.apple.com/documentation/cloudkit/quickstart)
- [Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [BikeCheck iCloud Architecture](./icloud-sync-architecture.md)
