import SwiftUI

struct HomeView: View {
    @State private var showingAddServiceIntervalView = false
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var bikesViewModel: BikesViewModel
    @EnvironmentObject var activitiesViewModel: ActivitiesViewModel
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @State var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
            ServiceView()
                .tabItem {
                    VStack {
                        Image(systemName: "timer")
                        Text("Service Intervals")
                    }
                }
                .tag(0)
            
            BikesView(selectedTab: $selectedTab)
                .tabItem {
                    VStack {
                        Image(systemName: "bicycle")
                        Text("Bikes")
                    }
                }
                .tag(1)
            
            ActivitiesView()
                .tabItem {
                    VStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("Activities")
                    }
                }
                .tag(2)
            }
            .onAppear {
                // Handle UI testing flags for onboarding state
                if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                    if ProcessInfo.processInfo.arguments.contains("COMPLETED_ONBOARDING") {
                        // For non-onboarding tests, mark onboarding as complete
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    } else if ProcessInfo.processInfo.arguments.contains("CLEAR_ONBOARDING") {
                        // For onboarding tests, explicitly clear the flag
                        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                    }
                    // If neither flag is present, preserve existing UserDefaults state
                }

                // Show onboarding for first-time users (after login or demo mode)
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    onboardingViewModel.startOnboarding()
                } else {
                    // Only request notification permission if onboarding is already complete
                    requestNotificationPermission()
                }
                fetchStravaData()
            }
            .onChange(of: onboardingViewModel.showTour) { showTour in
                // Request notification permission when tour completes
                if !showTour {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    requestNotificationPermission()
                }
            }
            .onChange(of: onboardingViewModel.showOnboarding) { showOnboarding in
                if showOnboarding {
                    // When onboarding starts, switch to Service Intervals tab
                    selectedTab = 0
                } else if !onboardingViewModel.showTour {
                    // Mark onboarding complete if user skips and request notification permission
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    requestNotificationPermission()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            
            // Show onboarding overlay on HomeView (post-login)
            if onboardingViewModel.showOnboarding {
                OnboardingOverlay(onboardingViewModel: onboardingViewModel)
            }

            if onboardingViewModel.showTour {
                OnboardingTourOverlay(onboardingViewModel: onboardingViewModel, selectedTab: $selectedTab)
            }
        }
    }

    private func fetchStravaData() {
        // Use Task to handle async calls
        Task {
            // First check service intervals (needs to be awaited)
            // Note: Service interval notifications are handled by background tasks only
            // This prevents notification spam on app launch
            
            // Then get athlete data and activities
            await withCheckedContinuation { continuation in
                stravaService.getAthlete { _ in
                    continuation.resume()
                }
            }
            
            await withCheckedContinuation { continuation in
                stravaService.fetchActivities { _ in
                    continuation.resume()
                }
            }
            
            // Finally refresh ViewModels on the main thread
            await MainActor.run {
                bikesViewModel.loadBikes()
                activitiesViewModel.loadActivities()
                serviceViewModel.loadServiceIntervals()
            }
        }
    }

    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if !granted {
                print("Notification permissions not granted")
            } else {
                print("Notification permissions granted")
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("Received deep link: \(url)")
        
        // Handle bikecheck://service-interval/[UUID]
        if url.scheme == "bikecheck" && url.host == "service-interval" {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2, let uuidString = pathComponents.last, let uuid = UUID(uuidString: uuidString) {
                navigateToServiceInterval(id: uuid)
            }
        }
    }
    
    private func navigateToServiceInterval(id: UUID) {
        // Switch to Service Intervals tab
        selectedTab = 0
        
        // Give the tab switch time to complete, then trigger service interval navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Post notification to ServiceView to navigate to specific interval
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowServiceIntervalDetail"),
                object: nil,
                userInfo: ["serviceIntervalID": id]
            )
        }
    }
}

struct ProfileImageView: View {
    @EnvironmentObject var stravaService: StravaService
    
    var body: some View {
        NavigationLink(destination: ProfileView()) {
            Group {
                if let image = stravaService.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                }
            }
        }
    }
}