import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var stravaService: StravaService
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
        .navigationBarHidden(true)
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
}

#Preview {
    ProfileView()
        .environmentObject(StravaService.shared)
}
