# iOS Configuration Setup

## Setting up Strava Credentials

### 1. Configure xcconfig Files
The `Config/Secrets.xcconfig` file contains your actual Strava API credentials. This file is already set up with working values for local testing.

### 2. Xcode Project Setup
To use these configurations in Xcode:

1. **Add xcconfig files to your project:**
   - In Xcode, right-click your project and select "Add Files to [ProjectName]"
   - Navigate to the `Config/` directory and add `Debug.xcconfig` and `Release.xcconfig`
   - **DO NOT add `Secrets.xcconfig` directly to Xcode** (it's imported automatically)

2. **Set Configuration Files:**
   - Select your project in Xcode Navigator
   - Go to your project settings → Info tab
   - Under "Configurations":
     - Set Debug configuration to use `Debug.xcconfig`
     - Set Release configuration to use `Release.xcconfig`

### 3. How It Works
- `Secrets.xcconfig` contains your actual credentials (gitignored)
- `Debug.xcconfig` and `Release.xcconfig` import the secrets
- Xcode substitutes `$(STRAVA_CLIENT_ID)` in Info.plist with actual values
- Swift code reads credentials from `Bundle.main` at runtime

### 4. For Team Development
When sharing with other developers:
1. Share the `Config/Secrets.xcconfig.example` file
2. Each developer creates their own `Config/Secrets.xcconfig` with their credentials
3. The actual secrets file stays local and never gets committed

## Security Notes
- ✅ `Secrets.xcconfig` is gitignored and won't be committed
- ✅ Each environment can have different credentials
- ✅ Easy to manage across Debug/Release builds
- ✅ Follows iOS best practices for configuration management