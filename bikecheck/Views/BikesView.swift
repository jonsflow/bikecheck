import SwiftUI

struct BikesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: BikesViewModel
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading bikes...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.bikes.isEmpty {
                    Text("No bikes found")
                } else {
                    List {
                        ForEach(viewModel.bikes, id: \.self) { bike in
                            ZStack {
                                BikeCardView(bike: bike, viewModel: viewModel)
                                NavigationLink(destination: BikeDetailView(bike: bike, selectedTab: $selectedTab)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                        
                        AdContainerView()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Bikes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: ProfileImageView())
            .onAppear {
                viewModel.loadBikes()
            }
        }
    }
    
}

struct BikeCardView: View {
    let bike: Bike
    let viewModel: BikesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bike.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Mountain Bike")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "bicycle")
                    .font(.callout)
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ride Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(viewModel.getTotalRideTime(for: bike))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                        Text("Good")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

