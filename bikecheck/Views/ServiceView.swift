import SwiftUI

struct ServiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ServiceViewModel
    @State private var showingServiceIntervalView = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0
    
    private var displayServiceIntervals: [ServiceInterval] {
        let intervalsByBike = Dictionary(grouping: viewModel.serviceIntervals, by: \.bike)
        var result: [ServiceInterval] = []
        
        for bike in intervalsByBike.keys.sorted(by: { $0.name < $1.name }) {
            guard let intervals = intervalsByBike[bike] else { continue }
            
            // Find overdue services (current usage >= interval time)
            let overdueServices = intervals.filter { interval in
                let currentUsage = getCurrentUsage(for: interval)
                return currentUsage >= interval.intervalTime
            }
            
            // Add all overdue services
            result.append(contentsOf: overdueServices.sorted { interval1, interval2 in
                let usage1 = getCurrentUsage(for: interval1)
                let usage2 = getCurrentUsage(for: interval2)
                return (usage1 - interval1.intervalTime) > (usage2 - interval2.intervalTime) // Most overdue first
            })
            
            // If no overdue services, or we want to show next service regardless
            let nonOverdueServices = intervals.filter { interval in
                let currentUsage = getCurrentUsage(for: interval)
                return currentUsage < interval.intervalTime
            }
            
            if let nextService = nonOverdueServices.min(by: { interval1, interval2 in
                let remaining1 = interval1.intervalTime - getCurrentUsage(for: interval1)
                let remaining2 = interval2.intervalTime - getCurrentUsage(for: interval2)
                return remaining1 < remaining2
            }) {
                result.append(nextService)
            }
        }
        
        return result
    }
    
    private func getCurrentUsage(for serviceInterval: ServiceInterval) -> Double {
        let totalRideTime = serviceInterval.bike.rideTime(context: viewContext)
        return totalRideTime - serviceInterval.startTime
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
                    serviceIntervalsList
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
        let totalRideTime = serviceInterval.bike.rideTime(context: viewContext)
        return totalRideTime - serviceInterval.startTime
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
                    Text(serviceInterval.bike.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Service \(serviceInterval.part.lowercased())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .italic()
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

