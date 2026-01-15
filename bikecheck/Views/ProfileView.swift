import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let profileImage = stravaService.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
            }
            
            if let athlete = stravaService.athlete {
                Text((athlete.firstname))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 12) {
                Text("Strava Connection")
                    .font(.headline)

                Text("Status: \(connectionStatusText)")
                    .foregroundColor(connectionStatusColor)

                if isDemoMode {
                    Text("Demo Mode Active")
                        .foregroundColor(.orange)
                }
            }

            // Small, unobtrusive restart tour button
            Button(action: {
                restartTour()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Restart Tour")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }

            Button(action: {
                showLogoutAlert = true
            }) {
                Text("Sign Out")
                    .frame(width: 280, height: 60)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var connectionStatusText: String {
        if isDemoMode {
            return "Demo Mode"
        } else if stravaService.isSignedIn == true {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
    
    private var connectionStatusColor: Color {
        if isDemoMode {
            return .orange
        } else if stravaService.isSignedIn == true {
            return .green
        } else {
            return .red
        }
    }
    
    private var isDemoMode: Bool {
        return stravaService.tokenInfo?.expiresAt == 9999999999
    }
    
    private func lastSyncText(tokenInfo: TokenInfo) -> String {
        if isDemoMode {
            return "Demo data loaded"
        } else {
            let date = Date(timeIntervalSince1970: TimeInterval(tokenInfo.expiresAt))
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func logout() {
        stravaService.logout()
    }

    private func restartTour() {
        // Reset onboarding state and start the tour
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        onboardingViewModel.startOnboarding()

        // Dismiss ProfileView to return to HomeView
        // HomeView will show onboarding overlay on the Service Intervals tab
        dismiss()
    }
}

#Preview {
    ProfileView()
        .environmentObject(StravaService.shared)
        .environmentObject(OnboardingViewModel())
}
