import SwiftUI

struct ServiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ServiceViewModel
    @State private var showingServiceIntervalView = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0
    
    private var sortedBikes: [Bike] {
        Array(viewModel.serviceIntervalsByBike.keys).sorted { $0.name < $1.name }
    }
    
    private var serviceIntervalsList: some View {
        List {
            ForEach(sortedBikes, id: \.self) { bike in
                Section {
                    ForEach(intervalsForBike(bike), id: \.self) { serviceInterval in
                        NavigationLink(value: serviceInterval) {
                            ServiceIntervalRowView(serviceInterval: serviceInterval, viewModel: viewModel)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    BikeHeaderView(bike: bike)
                        .onTapGesture {
                            navigationPath.append(bike)
                        }
                }
            }
            
            AdContainerView()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
    }
    
    private func intervalsForBike(_ bike: Bike) -> [ServiceInterval] {
        return viewModel.serviceIntervalsByBike[bike] ?? []
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
            .navigationDestination(for: Bike.self) { bike in
                BikeDetailView(bike: bike, selectedTab: $selectedTab)
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

struct BikeHeaderView: View {
    let bike: Bike
    
    var body: some View {
        HStack {
            Text(bike.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct ServiceIntervalRowView: View {
    let serviceInterval: ServiceInterval
    let viewModel: ServiceViewModel
    
    var body: some View {
        let timeUntilService = viewModel.calculateTimeUntilService(for: serviceInterval)
        let isOverdue = timeUntilService <= 0
        let urgencyLevel = getUrgencyLevel(timeUntilService: timeUntilService)
        
        HStack(spacing: 12) {
            Image(systemName: getIconName(for: serviceInterval.part))
                .font(.callout)
                .foregroundColor(urgencyLevel.color)
                .frame(width: 28, height: 28)
                .background(urgencyLevel.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceInterval.part)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(isOverdue ? 
                     "\(String(format: "%.1f", abs(timeUntilService))) hrs overdue" : 
                     "\(String(format: "%.1f", timeUntilService)) hrs remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(urgencyLevel.color)
                    .frame(width: 8, height: 8)
                Text(urgencyLevel.statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(urgencyLevel.color)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getUrgencyLevel(timeUntilService: Double) -> UrgencyLevel {
        let percentageRemaining = timeUntilService / serviceInterval.intervalTime
        
        if percentageRemaining <= 0 {
            return .now
        } else if percentageRemaining <= 0.20 {
            return .soon
        } else {
            return .good
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
        case let p where p.contains("oil"), let p where p.contains("fluid"):
            return "drop.fill"
        case let p where p.contains("filter"):
            return "air.purifier"
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

