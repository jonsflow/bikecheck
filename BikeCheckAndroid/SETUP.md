# Android Setup Instructions

## Strava API Credentials

To run the Android app, you need to configure your Strava API credentials:

1. Create a file `BikeCheckAndroid/local.properties` (this file is gitignored)
2. Add your Strava credentials:

```
STRAVA_CLIENT_ID=YOUR_ACTUAL_CLIENT_ID
STRAVA_CLIENT_SECRET=YOUR_ACTUAL_CLIENT_SECRET
```

3. Update `BikeCheckAndroid/app/build.gradle` to read from local.properties:

Replace the buildConfigField lines in defaultConfig with:

```gradle
Properties localProperties = new Properties()
if (rootProject.file('local.properties').exists()) {
    localProperties.load(rootProject.file('local.properties').newDataInputStream())
}

buildConfigField "String", "STRAVA_CLIENT_ID", "\"${localProperties.getProperty('STRAVA_CLIENT_ID', 'YOUR_STRAVA_CLIENT_ID')}\""
buildConfigField "String", "STRAVA_CLIENT_SECRET", "\"${localProperties.getProperty('STRAVA_CLIENT_SECRET', 'YOUR_STRAVA_CLIENT_SECRET')}\""
```

## Security Notes

- Never commit actual API credentials to version control
- The `local.properties` file is automatically ignored by git
- For CI/CD, use environment variables or secure build secrets