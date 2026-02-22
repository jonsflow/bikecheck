import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var stravaService: StravaService
    @State private var showLogoutAlert = false

    var body: some View {
        VStack(spacing: 30) {
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
                Text(athlete.firstname)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
        .navigationTitle("Profile")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive, action: { showLogoutAlert = true }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                stravaService.logout()
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
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(StravaService.shared)
    }
}
