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
                // Only request notification permission if not in tour mode
                if !onboardingViewModel.showTour {
                    requestNotificationPermission()
                }
                fetchStravaData()
            }
            .onChange(of: onboardingViewModel.showTour) { showTour in
                // Request notification permission when tour completes
                if !showTour {
                    requestNotificationPermission()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
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
            await stravaService.checkServiceIntervals()
            
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