# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BikeCheck is a bike maintenance tracking application available on both iOS and Android platforms. The app integrates with Strava to sync bikes and activities, helping cyclists track maintenance schedules based on actual ride time.

## Repository Structure

This is a multi-platform repository:

- **iOS App**: Root directory contains SwiftUI iOS application
- **Android App**: `BikeCheckAndroid/` contains modern Android application built with Kotlin

## Android Development

### Build Commands

```bash
cd BikeCheckAndroid
./gradlew build                    # Build the project
./gradlew assembleDebug           # Build debug APK
./gradlew assembleRelease         # Build release APK
./gradlew test                    # Run unit tests
./gradlew connectedAndroidTest    # Run instrumented tests
./gradlew clean                   # Clean build artifacts
```

### Setup Requirements

1. **Strava API Credentials**: Create `BikeCheckAndroid/local.properties` with:
   ```
   STRAVA_CLIENT_ID=your_client_id
   STRAVA_CLIENT_SECRET=your_client_secret
   ```

2. **Prerequisites**: Android SDK 24+, Android Studio Arctic Fox+

### Architecture

- **Pattern**: MVVM with Hilt dependency injection
- **Database**: Room with TypeConverters and reactive Flow queries
- **Network**: Retrofit + OkHttp with Gson serialization
- **Background**: WorkManager with Hilt integration
- **UI**: Material Design 3 with ViewBinding

### Key Modules

- `data/database/`: Room entities, DAOs, and database configuration
- `data/network/`: Retrofit API service and response models  
- `data/repository/`: Repository pattern for data access
- `di/`: Hilt dependency injection modules (Database, Network, WorkManager)
- `ui/`: Activities, ViewModels, and UI components organized by feature
- `work/`: Background workers for data synchronization
- `services/`: Background services and notifications

### Database Schema

Core entities with relationships:
- `AthleteEntity`: User profile from Strava
- `BikeEntity`: Bike information with foreign key to athlete
- `ActivityEntity`: Ride activities with bike references
- `ServiceIntervalEntity`: Maintenance schedules for bike components
- `TokenInfoEntity`: OAuth token storage

### Navigation Structure

Bottom navigation with three main sections:
- **Service Intervals**: Maintenance dashboard showing upcoming/overdue services
- **Bikes**: List of user's bikes with detail views
- **Activities**: Recent rides from Strava

## iOS Development

### Architecture

- **Pattern**: MVVM with SwiftUI and Combine
- **Database**: Core Data with NSPersistentContainer
- **Network**: Alamofire for HTTP networking
- **Background**: BackgroundTasks framework

### Shared Services (Singletons)

- `StravaService.shared`: API integration and authentication
- `DataService.shared`: Core Data operations
- `PersistenceController.shared`: Core Data stack management
- `NotificationService.shared`: Local notification handling

### ViewModels

StateObject instances initialized at app level:
- `BikesViewModel`: Bike data management
- `ActivitiesViewModel`: Activity data processing
- `ServiceViewModel`: Service interval calculations
- `LoginViewModel`: Authentication flow

### Testing Framework

- **Unit Tests**: Dependency injection with MockPersistenceController and in-memory Core Data
- **UI Tests**: Automatic test data injection via `UI_TESTING` launch argument

## Common Development Patterns

### Data Synchronization

Both platforms follow similar patterns:
1. OAuth authentication with Strava
2. Fetch athlete profile, bikes, and activities
3. Store data locally (Room/Core Data)
4. Calculate service intervals based on ride time
5. Send notifications when maintenance is due

### Service Interval Logic

Components track maintenance based on ride hours:
- Each component has configurable hour intervals
- App calculates total ride time from activities
- Notifications trigger when intervals are exceeded
- Users can reset intervals after performing maintenance

### Background Processing

- **Android**: WorkManager with network/battery constraints
- **iOS**: BackgroundTasks for periodic sync and notifications

## Security Considerations

- API credentials stored in local.properties (Android) and excluded from version control
- OAuth tokens stored securely in local databases
- No sensitive data uploaded to external servers beyond Strava API calls

## Test Data

Both platforms include demo/test data functionality for development and testing without requiring Strava authentication.