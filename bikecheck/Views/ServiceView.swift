import SwiftUI

enum ServiceStatus: String, CaseIterable {
    case overdue = "Overdue"
    case dueSoon = "Soon"
    case good = "Good"
    case all = "All"
}

struct ServiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ServiceViewModel
    @State private var showingServiceIntervalView = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0
    @State private var selectedStatuses: Set<ServiceStatus> = [.all]
    
    private var displayServiceIntervals: [ServiceInterval] {
        return viewModel.serviceIntervals
            .filter { interval in
                // If "All" is selected, show everything
                if selectedStatuses.contains(.all) {
                    return true
                }
                
                let currentUsage = getCurrentUsage(for: interval)
                let usagePercent = currentUsage / interval.intervalTime
                
                // Check if interval matches any selected status
                return selectedStatuses.contains { status in
                    switch status {
                    case .overdue:
                        return usagePercent >= 1.0
                    case .dueSoon:
                        return usagePercent >= 0.9 && usagePercent < 1.0
                    case .good:
                        return usagePercent < 0.9
                    case .all:
                        return true
                    }
                }
            }
            .sorted { interval1, interval2 in
                // First sort by bike name
                if interval1.bike.name != interval2.bike.name {
                    return interval1.bike.name < interval2.bike.name
                }

                // Within same bike, sort by urgency (most overdue first)
                let usage1 = getCurrentUsage(for: interval1)
                let usage2 = getCurrentUsage(for: interval2)
                let percent1 = usage1 / interval1.intervalTime
                let percent2 = usage2 / interval2.intervalTime

                return percent1 > percent2
            }
    }
    
    private func getCurrentUsage(for serviceInterval: ServiceInterval) -> Double {
        let lastServiceDate = serviceInterval.lastServiceDate ?? Date()
        return serviceInterval.bike.rideTimeSince(date: lastServiceDate, context: viewContext)
    }
    
    private var serviceIntervalsList: some View {
        List {
            ForEach(displayServiceIntervals, id: \.self) { serviceInterval in
                ZStack {
                    ServiceIntervalCardView(serviceInterval: serviceInterval, viewModel: viewModel)
                    NavigationLink(value: serviceInterval) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Ad at bottom of list
            AdContainerView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
    }
    
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading service intervals...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.serviceIntervals.isEmpty {
                    VStack {
                        Text("No service intervals found")
                        
                        Button(action: {
                            showingServiceIntervalView = true
                        }) {
                            Text("Add Service Interval")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            ForEach(ServiceStatus.allCases, id: \.self) { status in
                                Button(action: {
                                    if status == .all {
                                        // If "All" is tapped, clear others and select only "All"
                                        selectedStatuses = [.all]
                                    } else {
                                        // For other statuses, toggle selection
                                        if selectedStatuses.contains(.all) {
                                            // If "All" was selected, clear it and select this status
                                            selectedStatuses = [status]
                                        } else if selectedStatuses.contains(status) {
                                            selectedStatuses.remove(status)
                                        } else {
                                            selectedStatuses.insert(status)
                                        }
                                    }
                                }) {
                                    Text(status.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            selectedStatuses.contains(status) ? 
                                            Color.blue : Color(.systemGray6)
                                        )
                                        .foregroundColor(
                                            selectedStatuses.contains(status) ? .white : .primary
                                        )
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        serviceIntervalsList
                    }
                }
            }
            .navigationTitle("Service Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: ProfileImageView(),
                trailing: HStack {
                    // Hidden test button for UI testing background task logic
                    if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                        Button("Test BG Task") {
                            Task {
                                await BackgroundTaskManager.shared.executeTaskLogicForTesting(identifier: .checkServiceInterval)
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.clear) // Hidden but accessible
                        .accessibilityIdentifier("TestBackgroundTask")
                    }
                    addButton
                }
            )
            .sheet(isPresented: $showingServiceIntervalView, onDismiss: {
                viewModel.loadServiceIntervals()
            }) {
                AddServiceIntervalView()
            }
            .onAppear {
                viewModel.loadServiceIntervals()
            }
            .navigationDestination(for: ServiceInterval.self) { serviceInterval in
                AddServiceIntervalView(serviceInterval: serviceInterval)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowServiceIntervalDetail"))) { notification in
                // Handle navigation to specific service interval detail
                if let serviceIntervalID = notification.userInfo?["serviceIntervalID"] as? UUID {
                    navigateToServiceIntervalDetail(id: serviceIntervalID)
                }
            }
        }
    }
    
    
    var addButton: some View {
        Button(action: {
            showingServiceIntervalView = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    private func navigateToServiceIntervalDetail(id: UUID) {
        // Find the service interval with the matching ID
        if let serviceInterval = viewModel.serviceIntervals.first(where: { $0.id == id }) {
            // Add to navigation path to trigger navigation
            navigationPath.append(serviceInterval)
        } else {
            print("Service interval with ID \(id) not found")
            // Reload service intervals in case they haven't loaded yet
            viewModel.loadServiceIntervals()
            
            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let serviceInterval = viewModel.serviceIntervals.first(where: { $0.id == id }) {
                    navigationPath.append(serviceInterval)
                }
            }
        }
    }
}

struct ServiceIntervalCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let serviceInterval: ServiceInterval
    let viewModel: ServiceViewModel
    
    private var currentUsage: Double {
        let lastServiceDate = serviceInterval.lastServiceDate ?? Date()
        return serviceInterval.bike.rideTimeSince(date: lastServiceDate, context: viewContext)
    }
    
    private var fractionColor: Color {
        let percentage = currentUsage / serviceInterval.intervalTime
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.9 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceInterval.part)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(serviceInterval.bike.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: getIconName(for: serviceInterval.part))
                        .font(.callout)
                        .foregroundColor(fractionColor)
                        .rotationEffect(
                            serviceInterval.part.lowercased().contains("fork") ? .degrees(180) :
                            serviceInterval.part.lowercased().contains("chain") ? .degrees(40) :
                            .degrees(0)
                        )
                        .frame(width: 28, height: 28)
                        .background(fractionColor.opacity(0.1))
                        .clipShape(Circle())

                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(fractionColor)
                }
            }

            HStack(spacing: 16) {
                Text(dueText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(fractionColor)

                Spacer()

                WearIndicator(usagePercent: currentUsage / serviceInterval.intervalTime, color: fractionColor)
                    .frame(width: 80)
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
    
    private var statusText: String {
        let percentage = currentUsage / serviceInterval.intervalTime
        if percentage >= 1.0 {
            return "Now"
        } else if percentage >= 0.9 {
            return "Soon"
        } else {
            return "Good"
        }
    }
    
    private var dueText: String {
        let percentage = currentUsage / serviceInterval.intervalTime
        if percentage >= 1.0 {
            return "Now"
        } else {
            let remainingTime = serviceInterval.intervalTime - currentUsage
            return "In \(Int(remainingTime)) hours"
        }
    }
    
    private func getIconName(for part: String) -> String {
        switch part.lowercased() {
        case let p where p.contains("chain"):
            return "link"
        case let p where p.contains("brake"):
            return "brake.signal"
        case let p where p.contains("tire"), let p where p.contains("wheel"):
            return "circle.dotted"
        case let p where p.contains("fork"):
            return "tuningfork"
        case let p where p.contains("shock"):
            return "bolt"
        default:
            return "gear"
        }
    }
}


struct WearIndicator: View {
    let usagePercent: Double
    let color: Color
    let segmentCount: Int = 5

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    let remainingPercent = 1.0 - usagePercent
                    let segmentThreshold = Double(segmentCount - index) / Double(segmentCount)
                    let isFilled = remainingPercent >= segmentThreshold

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isFilled ? color : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
        }
        .frame(height: 4)
    }
}

enum UrgencyLevel {
    case good, soon, now

    var color: Color {
        switch self {
        case .good:
            return .green
        case .soon:
            return .orange
        case .now:
            return .red
        }
    }

    var statusText: String {
        switch self {
        case .good:
            return "Good"
        case .soon:
            return "Soon"
        case .now:
            return "Now"
        }
    }
}

