import SwiftUI

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @StateObject private var viewModel: BikeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    @Binding var selectedTab: Int
    @State private var showingIntervalsCreatedAlert = false
    @State private var showingDatePicker = false
    @State private var showingBatchUpdateDatePicker = false
    @State private var selectedDate = Date()
    
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
                    let intervals = bike.serviceIntervals(from: viewContext).sorted { $0.part < $1.part }

                    if intervals.isEmpty {
                        // Empty state - offer both options
                        Button(action: {
                            selectedDate = Date()
                            showingDatePicker = true
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

                        // Batch update all intervals' last service date
                        Button(action: {
                            selectedDate = Date()
                            showingBatchUpdateDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.orange)
                                Text("Set Last Service Date for All")
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                        }
                        .accessibilityIdentifier("BatchUpdateServiceDatesButton")

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        selectedDate = Date()
                        showingDatePicker = true
                    }) {
                        Label("Create Default Service Intervals", systemImage: "plus.circle.fill")
                    }

                    let intervals = bike.serviceIntervals(from: viewContext)
                    if !intervals.isEmpty {
                        Button(action: {
                            selectedDate = Date()
                            showingBatchUpdateDatePicker = true
                        }) {
                            Label("Set Last Service Date for All", systemImage: "calendar")
                        }
                    }

                    Button(action: {
                        viewModel.showingConfirmationDialog = true
                    }) {
                        Label("Delete Bike", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("More")
                        .accessibilityIdentifier("BikeDetailOverflowMenu")
                }
            }
        }
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
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("When did you last service this bike?")
                        .font(.headline)
                        .padding(.top)

                    DatePicker("Last Service Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()

                    Spacer()
                }
                .navigationTitle("Set Service Date")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingDatePicker = false
                    },
                    trailing: Button("Create") {
                        viewModel.createDefaultServiceIntervals(lastServiceDate: selectedDate)
                        showingDatePicker = false
                        showingIntervalsCreatedAlert = true
                        serviceViewModel.loadServiceIntervals()
                    }
                )
            }
        }
        .sheet(isPresented: $showingBatchUpdateDatePicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Set last service date for all intervals on this bike")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)

                    DatePicker("Last Service Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()

                    Text("This will update all service intervals to calculate from this date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .navigationTitle("Update All Intervals")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingBatchUpdateDatePicker = false
                    },
                    trailing: Button("Update") {
                        viewModel.updateAllServiceDates(to: selectedDate)
                        showingBatchUpdateDatePicker = false
                        serviceViewModel.loadServiceIntervals()
                    }
                )
            }
        }
    }
}

struct CompactServiceIntervalRow: View {
    let serviceInterval: ServiceInterval
    let serviceViewModel: ServiceViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    private var currentUsage: Double {
        guard let bike = serviceInterval.getBike(from: viewContext) else {
            return 0
        }
        let lastServiceDate = serviceInterval.lastServiceDate ?? Date()
        return bike.rideTimeSince(date: lastServiceDate, context: viewContext)
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

