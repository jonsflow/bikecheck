# CloudKit Setup Guide for BikeCheck

This guide explains how to complete the iCloud/CloudKit setup for automatic data sync and persistence across app reinstalls.

## What Was Changed

### Code Changes (Already Complete)
1. **PersistenceController.swift** - Changed from `NSPersistentContainer` to `NSPersistentCloudKitContainer`
2. **bikecheck.entitlements** - Created with iCloud and CloudKit permissions

### Xcode Configuration (You Need to Do This)

#### Step 1: Add the Entitlements File to Your Target
1. Open `bikecheck.xcodeproj` in Xcode
2. Select the `bikecheck` target
3. Go to "Build Settings" tab
4. Search for "Code Signing Entitlements"
5. Set the value to: `bikecheck/bikecheck.entitlements`

#### Step 2: Enable iCloud Capability
1. Select the `bikecheck` target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" button
4. Select "iCloud"
5. Check the following boxes:
   - ☑️ CloudKit
   - ☑️ Key-value storage (optional, for small settings)

#### Step 3: Configure CloudKit Container
After adding the iCloud capability, Xcode will automatically create a CloudKit container.

**Default container name will be:** `iCloud.com.yourteam.bikecheck` (or similar based on your bundle ID)

1. In the iCloud capability section, verify the container is selected
2. The container identifier should match what's in `bikecheck.entitlements`

**Note:** If you haven't set up your Apple Developer account in Xcode:
- Go to Xcode → Preferences → Accounts
- Add your Apple ID
- Select your team

#### Step 4: Verify Bundle Identifier
1. In the "General" tab of your target
2. Confirm your Bundle Identifier (e.g., `com.yourteam.bikecheck`)
3. The CloudKit container will automatically use this: `iCloud.$(CFBundleIdentifier)`

## How It Works

### Automatic Sync
- Every time you save to Core Data, changes automatically sync to iCloud
- Changes from other devices automatically sync down via push notifications
- No manual backup/restore needed - completely transparent to users

### Data Persistence Across Reinstalls
1. User deletes BikeCheck app
2. Core Data is deleted from device
3. User reinstalls BikeCheck app
4. NSPersistentCloudKitContainer automatically downloads all data from iCloud
5. User sees all their bikes, service intervals, and activities restored

### Multi-Device Sync
- Same iCloud account on multiple devices (iPhone, iPad, Mac)
- Changes on one device appear on all devices
- Automatic conflict resolution with CloudKit's CRDTs

### Offline Support
- Core Data still works locally when offline
- Changes queue up and sync when connection is restored
- No data loss during offline periods

## Testing

### Test 1: Basic Sync
1. Build and run on Device/Simulator A
2. Add a bike and service interval
3. Build and run on Device/Simulator B (same iCloud account)
4. Wait ~30 seconds
5. Verify data appears on Device B

### Test 2: Reinstall Persistence
1. Build and run app, add test data
2. Delete app from device
3. Reinstall and run app
4. Verify all data is restored from iCloud

### Test 3: Multi-Device Sync
1. Make changes on Device A
2. Verify changes appear on Device B within 30-60 seconds

## Troubleshooting

### "No iCloud account" Error
- Make sure you're signed into iCloud in Settings
- For simulator: Xcode → Window → Devices and Simulators → Select simulator → iCloud settings

### Data Not Syncing
- Check that both devices are signed into the same iCloud account
- Verify iCloud Drive is enabled in Settings → iCloud
- Check Console app for CloudKit errors (filter by "CloudKit" or "NSPersistentCloudKitContainer")

### Testing Mode (In-Memory Store)
The code automatically disables CloudKit for in-memory stores:
```swift
if inMemory {
    container.persistentStoreDescriptions.first!.cloudKitContainerOptions = nil
}
```
This ensures unit tests don't try to sync to iCloud.

## Privacy Considerations

### What Gets Synced
- All Core Data entities: Bikes, ServiceIntervals, Activities, Athlete, TokenInfo
- User's personal bike maintenance data

### What Doesn't Get Synced
- UserDefaults (like "hasCompletedOnboarding")
- Strava profile images (binary data can be synced but consider size limits)
- App preferences

### Privacy Policy Update Needed
Add to your privacy policy:
> BikeCheck uses iCloud to sync your bike and service data across your devices and preserve your data if you reinstall the app. Your data is stored in your personal iCloud account and is not accessible to us or other users.

## CloudKit Dashboard

To view and manage your CloudKit data:
1. Go to [https://icloud.developer.apple.com/](https://icloud.developer.apple.com/)
2. Sign in with your Apple Developer account
3. Select your CloudKit container
4. View schema, records, and sync activity

## Performance Notes

### Storage Limits
- CloudKit provides generous free tier:
  - 10GB database storage per user
  - 200MB asset storage per user
  - Transfer limits scale with app usage

### Best Practices
- Core Data entities with `@NSManaged` properties work automatically
- Binary data (images) should be stored as separate CloudKit assets if large
- Consider adding indices to frequently queried attributes

## Next Steps

After completing Xcode configuration:
1. Build and run the app
2. Add test data (bikes, service intervals)
3. Check Xcode console for any CloudKit errors
4. Test on two devices/simulators with same iCloud account
5. Verify sync works in both directions

## Support Resources

- [Apple: Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/setting_up_core_data_with_cloudkit)
- [Apple: Syncing a Core Data Store with CloudKit](https://developer.apple.com/documentation/coredata/syncing-a-core-data-store-with-cloudkit)
- [WWDC Videos on CloudKit](https://developer.apple.com/videos/cloudkit)
