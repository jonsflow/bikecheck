import SwiftUI

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @StateObject private var viewModel: BikeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    @Binding var selectedTab: Int
    @State private var showingIntervalsCreatedAlert = false
    
    init(bike: Bike, selectedTab: Binding<Int>) {
        self.bike = bike
        self._selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: BikeDetailViewModel(bike: bike))
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Bike Info")) {
                    Text(bike.name)
                    Text("\(viewModel.getMileage()) miles")
                    Text("\(viewModel.getTotalRideTime()) hrs")
                    Text("\(viewModel.getActivityCount()) activities")
                }
                
                Section(header: Text("Service Intervals")) {
                    let intervals = Array(bike.serviceIntervals ?? []).sorted { $0.part < $1.part }
                    
                    if intervals.isEmpty {
                        // Empty state - offer both options
                        Button(action: {
                            viewModel.createDefaultServiceIntervals()
                            showingIntervalsCreatedAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Create Default Service Intervals")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                        
                        NavigationLink(destination: AddServiceIntervalView()) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Create Custom Service Interval")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    } else {
                        // Show existing intervals
                        ForEach(intervals, id: \.id) { serviceInterval in
                            NavigationLink(destination: AddServiceIntervalView(serviceInterval: serviceInterval)) {
                                CompactServiceIntervalRow(serviceInterval: serviceInterval, serviceViewModel: serviceViewModel)
                            }
                        }
                        
                        // Add new service interval option
                        NavigationLink(destination: AddServiceIntervalView()) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Add Service Interval")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    AdContainerView()
                }
            }
        }
        .navigationTitle("Bike Details")
        .navigationBarItems(
            trailing: Menu {
                Button(action: {
                    viewModel.createDefaultServiceIntervals()
                    showingIntervalsCreatedAlert = true
                }) {
                    Label("Create Default Service Intervals", systemImage: "plus.circle.fill")
                }
                
                Button(action: {
                    viewModel.showingConfirmationDialog = true
                }) {
                    Label("Delete Bike", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityIdentifier("BikeDetailOverflowMenu")
        )
        .alert(isPresented: $showingIntervalsCreatedAlert) {
            Alert(
                title: Text("Service Intervals Created"),
                message: Text("Default service intervals have been created for \(bike.name)"),
                dismissButton: .default(Text("OK")) {
                    // Switch to the Service Intervals tab (index 0)
                    selectedTab = 0
                    // Navigate back to the bikes list
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $viewModel.showingConfirmationDialog) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this bike? You may loose all Service intervals and tracking associated with it, also if its a strava bike, it will be re-imported on the next sync"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteBike()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct CompactServiceIntervalRow: View {
    let serviceInterval: ServiceInterval
    let serviceViewModel: ServiceViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    private var currentUsage: Double {
        let totalRideTime = serviceInterval.bike.rideTime(context: viewContext)
        return totalRideTime - serviceInterval.startTime
    }
    
    private var statusColor: Color {
        let percentage = currentUsage / serviceInterval.intervalTime
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.9 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        let percentage = currentUsage / serviceInterval.intervalTime
        if percentage >= 1.0 {
            return "Now"
        } else {
            let remainingTime = serviceInterval.intervalTime - currentUsage
            return "In \(Int(remainingTime))h"
        }
    }
    
    private func getIconName(for part: String) -> String {
        switch part.lowercased() {
        case let p where p.contains("chain"):
            return "link"
        case let p where p.contains("fork"):
            return "tuningfork"
        case let p where p.contains("shock"):
            return "bolt"
        default:
            return "gear"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: getIconName(for: serviceInterval.part))
                .font(.callout)
                .foregroundColor(statusColor)
                .frame(width: 24, height: 24)
                .rotationEffect(
                    serviceInterval.part.lowercased().contains("fork") ? .degrees(180) :
                    serviceInterval.part.lowercased().contains("chain") ? .degrees(20) :
                    .degrees(0)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceInterval.part)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Every \(Int(serviceInterval.intervalTime)) hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
    }
}

