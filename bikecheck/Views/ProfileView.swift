import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var stravaService: StravaService
    @State private var showLogoutAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Profile header
                VStack(spacing: 12) {
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

                    VStack(spacing: 6) {
                        Text("Status: \(connectionStatusText)")
                            .foregroundColor(connectionStatusColor)

                        if isDemoMode {
                            Text("Demo Mode Active")
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal)

                // Stats section
                ProfileStatsView()
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
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
