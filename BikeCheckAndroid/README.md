# BikeCheck Android

A comprehensive Android bike maintenance tracking application built with modern Android development practices.

## Features

### 🔐 Authentication
- Strava OAuth integration using Chrome Custom Tabs
- Secure token storage with Room database
- Test data insertion for development and demo purposes

### 🚴 Bike Management
- View all bikes synced from Strava
- Display bike names and total distance
- Material Design card-based UI

### ⚙️ Service Intervals
- Track maintenance intervals for bike components
- Set custom time intervals for different parts
- Notification support for upcoming maintenance

### 📊 Activity Tracking
- Display recent cycling activities
- Show activity details (distance, time, speed)
- Dedicated activities screen with complete history
- Auto-sync from Strava (when authenticated)

### 📱 Modern UI/UX
- Material Design 3 components
- Responsive layouts with NestedScrollView
- Loading states and progress indicators
- Intuitive navigation between screens

### 🔄 Background Sync
- WorkManager integration for periodic data sync
- Network-aware background tasks
- Battery optimization with smart scheduling

## Architecture

### MVVM Pattern
- **Model**: Room database entities and network models
- **View**: Activities with ViewBinding
- **ViewModel**: LiveData/StateFlow for reactive UI updates

### Dependency Injection
- Hilt for compile-time dependency injection
- Modular DI setup (Database, Network, WorkManager)
- Clean separation of concerns

### Database Layer
- Room database with TypeConverters
- Foreign key relationships between entities
- DAO interfaces with Flow-based reactive queries

### Network Layer
- Retrofit for HTTP client
- Gson for JSON serialization
- OkHttp logging interceptor for debugging

### Background Processing
- WorkManager for reliable background tasks
- Hilt integration for dependency injection in workers
- Constraints-based scheduling (network, battery)

## Project Structure

```
app/src/main/java/com/bikecheck/android/
├── data/
│   ├── database/
│   │   ├── entities/     # Room entities
│   │   ├── dao/          # Data Access Objects
│   │   └── AppDatabase.kt
│   ├── network/
│   │   ├── models/       # API response models
│   │   └── StravaApiService.kt
│   └── repository/
│       └── StravaRepository.kt
├── di/                   # Dependency injection modules
├── services/             # Background services
├── ui/
│   ├── activities/       # Activities screen
│   ├── home/            # Home dashboard
│   ├── login/           # Authentication
│   └── MainActivity.kt   # App entry point
├── utils/               # Utilities and constants
├── work/                # Background workers
└── BikeCheckApplication.kt
```

## Key Dependencies

- **Room**: Local database with reactive queries
- **Retrofit**: REST API client for Strava integration
- **Hilt**: Dependency injection framework
- **WorkManager**: Background task scheduling
- **Material Components**: Modern UI components
- **Lifecycle Components**: MVVM architecture support
- **Coroutines**: Asynchronous programming

## Getting Started

### Prerequisites
- Android Studio Arctic Fox or later
- Android SDK 24+ (API level 24)
- Strava Developer Account (for OAuth credentials)

### Setup
1. Clone the repository
2. Open in Android Studio
3. Update Strava API credentials in `Constants.kt`
4. Build and run the application

### Testing
- Use "Insert Test Data" button for demo data
- Real Strava integration requires valid OAuth setup
- All core functionality works offline with test data

## Future Enhancements

- Push notifications for service reminders
- Enhanced data sync with conflict resolution
- Detailed service history tracking
- Export functionality for maintenance records
- Integration with additional fitness platforms
- Advanced analytics and reporting

## Development Notes

This implementation provides a solid foundation that mirrors the iOS BikeCheck app's core functionality while following Android best practices and modern development patterns. The architecture is designed for maintainability, testability, and future feature expansion.