import SwiftUI

struct BikesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: BikesViewModel
    @EnvironmentObject var serviceViewModel: ServiceViewModel
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
                            BikeCardView(bike: bike, viewModel: viewModel, serviceViewModel: serviceViewModel, selectedTab: $selectedTab)
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
    let serviceViewModel: ServiceViewModel
    @Binding var selectedTab: Int
    @State private var isExpanded: Bool = false
    @State private var showingBikeDetail: Bool = false
    
    private var bikeServiceIntervals: [ServiceInterval] {
        serviceViewModel.serviceIntervals.filter { $0.bike == bike }
    }
    
    var body: some View {
        ZStack {
            NavigationLink(destination: BikeDetailView(bike: bike, selectedTab: $selectedTab), isActive: $showingBikeDetail) {
                EmptyView()
            }
            .opacity(0)

            VStack(alignment: .leading, spacing: 8) {
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
                        .onTapGesture {
                            showingBikeDetail = true
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                showingBikeDetail = true
                            }) {
                                Image(systemName: "bicycle")
                                    .font(.callout)
                                    .foregroundColor(.blue)
                                    .frame(width: 28, height: 28)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
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

                if isExpanded {
                    ServiceIntervalsSection(serviceIntervals: bikeServiceIntervals, serviceViewModel: serviceViewModel)
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
}

struct ServiceIntervalsSection: View {
    let serviceIntervals: [ServiceInterval]
    let serviceViewModel: ServiceViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !serviceIntervals.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                Text("Service Intervals")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                ForEach(serviceIntervals, id: \.id) { interval in
                    ServiceIntervalMiniRow(serviceInterval: interval, serviceViewModel: serviceViewModel)
                }
            }
        }
    }
}

struct ServiceIntervalMiniRow: View {
    let serviceInterval: ServiceInterval
    let serviceViewModel: ServiceViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    private func getCurrentUsage(for serviceInterval: ServiceInterval) -> Double {
        let lastServiceDate = serviceInterval.lastServiceDate ?? Date()
        return serviceInterval.bike.rideTimeSince(date: lastServiceDate, context: viewContext)
    }
    
    private func getStatusText() -> String {
        let currentUsage = getCurrentUsage(for: serviceInterval)
        let remainingTime = serviceInterval.intervalTime - currentUsage
        
        if remainingTime <= 0 {
            return "Now"
        } else {
            return "in \(String(format: "%.0f", remainingTime))h"
        }
    }
    
    private func getStatusColor() -> Color {
        let currentUsage = getCurrentUsage(for: serviceInterval)
        let usagePercent = currentUsage / serviceInterval.intervalTime
        
        if usagePercent >= 1.0 {
            return .red
        } else if usagePercent >= 0.9 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getComponentIcon() -> String {
        switch serviceInterval.part.lowercased() {
        case "chain":
            return "link"
        case "fork lowers":
            return "tuningfork"
        case "shock":
            return "bolt"
        default:
            return "wrench"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: getComponentIcon())
                .font(.callout)
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(serviceInterval.part.lowercased() == "chain" ? 20 : 0))
                .rotationEffect(.degrees(serviceInterval.part.lowercased() == "fork lowers" ? 180 : 0))
            
            Text(serviceInterval.part)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(getStatusText())
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(getStatusColor())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.secondarySystemBackground))
                .opacity(0.5)
        )
    }
}

