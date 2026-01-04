# BikeCheck Project Documentation

> Developer and AI Assistant Reference

## Current Development State (as of January 3, 2026)

### Recent Major Features Completed
- **Notification Throttling** (January 2026): 7-day throttle window prevents notification spam for overdue service intervals
- **Core Data Migration** (January 2026): Implemented lightweight migration as proof of concept for future schema changes
- **Strava Activity Limit Increase** (December 2025): Increased from 30 to 200 activities to ensure adequate ride history
- **Custom Last Service Date** (December 2025): Users can set custom service start dates for accurate tracking
- **Service Interval Filtering** (October 2025): Smart filtering with status-based tabs (Overdue/Soon/Good/All)
- **UI Testing Infrastructure**: Comprehensive UI testing with automatic test data injection
- **Onboarding System**: Single-step onboarding flow with interactive test data tour
- **Background Tasks**: Service checking and Strava data syncing via BackgroundTaskManager

### Active Features
1. **Strava Integration** - OAuth flow and data sync for bikes and activities
2. **Service Interval Tracking** - CRUD operations with smart notifications
3. **Bike Management** - Import from Strava and manual management
4. **Activity Tracking** - Automatic sync with ride time calculations
5. **Onboarding Experience** - Single-step flow with test data tour
6. **Background Sync** - BackgroundTasks framework for iOS
7. **Notification System** - Local notifications with 7-day throttling
8. **UI Testing Suite** - Comprehensive test coverage with mock data injection

## Architecture

### Pattern: MVVM + Singleton Services
- **MVVM** - SwiftUI views with dedicated ViewModels for business logic
- **Core Data** - Persistence layer with automatic lightweight migration enabled
- **Singleton Services** - StravaService, DataService, NotificationService, PersistenceController
- **Background Tasks** - BackgroundTaskManager handles service checking and data synchronization
- **Environment Objects** - Services and ViewModels injected via SwiftUI environment

### Core Data Migration Strategy

BikeCheck implements automatic lightweight migration for schema changes:

**Migration Infrastructure:**
- Model versioning: `bikecheck.xcdatamodel` (v1) → `bikecheck 2.xcdatamodel` (v2)
- Automatic migration enabled via `NSMigratePersistentStoresAutomaticallyOption`
- Automatic mapping inference via `NSInferMappingModelAutomaticallyOption`
- Configured in `PersistenceController.swift:16-23`

**Recent Migration (Model v2 - January 2026):**
- Added `lastNotificationDate` property to `ServiceInterval` entity
- Enables notification throttling (max once per 7 days per service interval)
- Prevents notification spam for overdue service intervals
- Implemented as proof of concept for future production migrations

**Testing:**
- Comprehensive unit tests verify schema changes (`NotificationThrottlingTests.swift`)
- Migration tested with existing test data
- Backward compatibility verified (nil dates handled correctly)
- Serves as reference implementation for future migrations

This approach ensures seamless app updates when schema changes are required.

## Core Data Model (Version 2)

### Entities

**ServiceInterval**
- `id`: UUID (auto-generated)
- `part`: String (component name, e.g., "Chain")
- `intervalTime`: Double (hours between services)
- `lastServiceDate`: Date? (when service was last performed)
- `lastNotificationDate`: Date? (when notification was last sent - v2 addition)
- `notify`: Bool (whether to send notifications)
- `bike`: Relationship to Bike (many-to-one)

**Bike**
- `id`: String (Strava gear ID)
- `name`: String
- `distance`: Double (total distance in meters)
- `athlete`: Relationship to Athlete
- `serviceIntervals`: Relationship to ServiceInterval (one-to-many, cascade delete)

**Activity**
- `id`: Int64 (Strava activity ID)
- `name`: String
- `type`: String
- `distance`: Double?
- `movingTime`: Int64 (seconds)
- `startDate`: Date?
- `averageSpeed`: Double?
- `gearId`: String? (links to Bike)
- `processed`: Bool

**Athlete**
- `id`: Int64 (Strava athlete ID)
- `firstname`: String
- `profile`: String? (profile photo URL)
- `bikes`: Relationship to Bike (one-to-many)
- `tokenInfo`: Relationship to TokenInfo (one-to-one)

**TokenInfo**
- `accessToken`: String
- `refreshToken`: String
- `expiresAt`: Int64 (Unix timestamp)
- `athlete`: Relationship to Athlete (one-to-one)

## Key Services

### StravaService (Singleton)
- OAuth authentication flow
- Token management and refresh
- Fetches athlete data, bikes, and activities from Strava API
- Activity limit: 200 rides (covers ~1.3 years for typical riders)
- Checks service intervals and triggers notifications
- Demo mode for testing without Strava authentication

### NotificationService (Singleton)
- Requests user notification permissions
- Sends local notifications for overdue service intervals
- **Throttling**: Max one notification per service interval per 7 days (604800 seconds)
- Updates `lastNotificationDate` after successful notification
- Deep linking support (navigates to specific service interval on tap)
- Delegates background task scheduling to BackgroundTaskManager

### BackgroundTaskManager (Singleton)
- Centralized background task management
- Task identifiers: `checkServiceInterval`, `fetchActivities`
- Testing mode for development (prevents real task scheduling)
- Thread-safe task tracking and scheduling
- Manual task execution for UI testing via `executeTaskLogicForTesting()`
- Logging with os.log for debugging

### DataService (Singleton)
- Core Data fetch operations
- CRUD operations for all entities
- Creates default service intervals (Chain, Fork Lowers, Shock)
- Saves context with error handling

### PersistenceController (Singleton)
- Manages Core Data stack (NSPersistentContainer)
- Automatic lightweight migration enabled
- In-memory store option for testing
- Automatic merge of changes from parent context
- Merge policy: NSMergeByPropertyObjectTrumpMergePolicy

## ViewModels

All ViewModels are `@StateObject` instances created at app level (`bikecheckApp.swift`) to maintain state across view transitions.

- **BikesViewModel** - Manages bikes data and operations
- **ActivitiesViewModel** - Handles activity data processing
- **ServiceViewModel** - Manages service intervals and calculations
- **AddServiceIntervalViewModel** - Handles service interval creation/editing
- **BikeDetailViewModel** - Bike-specific data and operations
- **LoginViewModel** - Authentication flow management
- **OnboardingViewModel** - Onboarding tour state management

## Testing Infrastructure

### Unit Tests (`bikecheckTests/`)
- **MockPersistenceController**: In-memory Core Data for isolated testing
- **DataServiceTests**: Core Data operations and service interval logic
- **NotificationThrottlingTests**: Schema migration and throttling behavior (8 test cases)
- **PersistenceControllerTests**: Core Data stack configuration
- Test data creation utilities for consistent test scenarios

### UI Tests (`bikecheckUITests/`)
- **BikeCheckUITestCase**: Base class with automatic test data injection
- **bikecheckUITests**: Comprehensive workflow tests (navigation, CRUD, filtering)
- **OnboardingUITests**: Onboarding tour functionality
- Launch arguments: `UI_TESTING` flag triggers automatic test data loading
- Background task testing: Hidden button to manually trigger service checks

### Test Execution
- Unit tests: Xcode Test Navigator or `xcodebuild test`
- UI tests: Automatically inject test data via `StravaService.insertTestData()`
- CI/CD: GitHub Actions runs UI tests on PR and merge to main

## Background Tasks

Configured in `bikecheckApp.swift:30-46`:

1. **checkServiceInterval**
   - Runs every ~24 hours (iOS determines actual timing)
   - Checks all service intervals for due maintenance
   - Sends notifications (with 7-day throttling)
   - Only runs if user is signed in

2. **fetchActivities**
   - Fetches new activities from Strava
   - Updates ride time calculations
   - Reschedules itself after completion

Tasks are registered with `BGTaskScheduler` and managed by `BackgroundTaskManager`.

## Notification System Details

### Throttling Logic (NotificationService.swift:25-30)
```swift
// Throttle: max once per week (604800 seconds = 7 days)
if let lastNotificationDate = interval.lastNotificationDate,
   Date().timeIntervalSince(lastNotificationDate) < 604800 {
    logger.info("Skipping notification - sent within last 7 days")
    return
}
```

### Notification Flow
1. Background task runs `checkServiceIntervals()`
2. For each interval where `timeUntilService <= 0` and `notify == true`:
   - Check if notification was sent in last 7 days
   - If yes: skip (throttled)
   - If no: send notification and update `lastNotificationDate`
3. User taps notification → deep link to service interval detail

## Key Dependencies

- **Alamofire** - HTTP networking for Strava API
- **Core Data** - Local data persistence
- **Combine** - Reactive programming patterns
- **SwiftUI** - UI framework
- **BackgroundTasks** - Background processing
- **UserNotifications** - Local notification delivery
- **GoogleMobileAds** - Ad integration

## Development Workflow

### Branch Strategy
- `main` - Production-ready code
- `feature/*` - Feature development branches
- `develop` - Integration branch (if needed)

### Commit Guidelines
- No AI attribution in commit messages (user preference)
- Descriptive commit messages with context
- Reference issue numbers when closing issues

### CI/CD
- GitHub Actions workflow: `.github/workflows/test.yml`
- Runs on: push to main/develop, PRs, manual trigger
- Test jobs: Unit tests and UI tests on macOS-latest
- Simulator: Dynamically selected iPhone simulator

## Open Issues (As of January 2026)

### High Priority
- **#30** - OAuth Flow UI Testing with mocked responses
- **#28** - Detailed onboarding tour for ServiceInterval/BikeDetail views

### Enhancements
- **#51** - Smart bike detection with service interval presets
- **#50** - Database backup and restore functionality
- **#18** - Data Provider Abstraction
- **#17** - Garmin support
- **#16** - Wahoo API support
- **#9** - Service interval templates based on bike type
- **#4** - General enhancement suggestions

### Recently Closed
- **#31** - Core Data migration implementation ✅
- **#29** - Notification improvements (throttling) ✅
- **#15** - Background service test framework ✅
- **#10** - Dependency injection (decided singleton pattern is appropriate) ✅
- **#3** - Delete bike issues ✅

## Future Improvements

1. **Service History Tracking** - Log completed maintenance with notes/photos
2. **Component-specific Tracking** - Detailed part specifications and lifecycle
3. **Multiple Notification Thresholds** - Warn at 90%, 100%, etc.
4. **Additional Platform Integrations** - Garmin Connect, Wahoo, TrainingPeaks
5. **Export Functionality** - Export maintenance records to CSV/PDF
6. **Advanced Analytics** - Dashboard with component wear patterns
7. **Offline Mode** - Manual activity entry when offline
8. **Push Notifications** - Remote notifications for social features
9. **Cross-Platform Sync** - Cloud sync between devices
10. **Android Platform** - Native Android app with feature parity

## External Documentation

- **Public Documentation**: [BikeCheck Public Repo](https://github.com/jonsflow/bikecheck-public)
  - User-facing landing page
  - Privacy policy
  - Support and FAQ
- **Architecture Diagram**: `architecture-diagram.svg` (visual representation of app structure)

## Notes for AI Assistants

- This project uses **singleton pattern** for services (not dependency injection)
- **No AI attribution** in commits (user preference)
- CLAUDE.local.md is for local notes only (not tracked in git)
- This file (Claude.md) should be kept up-to-date with major changes
- Always run tests before committing schema changes
- Core Data migrations should be tested with existing data
- Background tasks can be manually triggered via hidden UI test button in ServiceView
