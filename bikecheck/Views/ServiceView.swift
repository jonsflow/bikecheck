import SwiftUI

struct ServiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ServiceViewModel
    @State private var showingServiceIntervalView = false
    @State private var selectedServiceInterval: ServiceInterval?
    @State private var showingServiceIntervalDetail = false
    
    var body: some View {
        NavigationView {
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
                    List {
                        ForEach(viewModel.serviceIntervals, id: \.self) { serviceInterval in
                            NavigationLink(
                                destination: AddServiceIntervalView(serviceInterval: serviceInterval),
                                tag: serviceInterval,
                                selection: $selectedServiceInterval
                            ) {
                                ServiceIntervalCardView(serviceInterval: serviceInterval, viewModel: viewModel)
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
            .navigationTitle("Service Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: profileImage,
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowServiceIntervalDetail"))) { notification in
                // Handle navigation to specific service interval detail
                if let serviceIntervalID = notification.userInfo?["serviceIntervalID"] as? UUID {
                    navigateToServiceIntervalDetail(id: serviceIntervalID)
                }
            }
        }
    }
    
    var profileImage: some View {
        Group {
            if let image = stravaService.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
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
            // Set the selected service interval to trigger navigation
            selectedServiceInterval = serviceInterval
        } else {
            print("Service interval with ID \(id) not found")
            // Reload service intervals in case they haven't loaded yet
            viewModel.loadServiceIntervals()
            
            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let serviceInterval = viewModel.serviceIntervals.first(where: { $0.id == id }) {
                    selectedServiceInterval = serviceInterval
                }
            }
        }
    }
}

struct ServiceIntervalCardView: View {
    let serviceInterval: ServiceInterval
    let viewModel: ServiceViewModel
    
    var body: some View {
        let timeUntilService = viewModel.calculateTimeUntilService(for: serviceInterval)
        let isOverdue = timeUntilService <= 0
        let urgencyLevel = getUrgencyLevel(timeUntilService: timeUntilService)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceInterval.bike.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Service \(serviceInterval.part.lowercased())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: getIconName(for: serviceInterval.part))
                    .font(.title3)
                    .foregroundColor(urgencyLevel.color)
                    .frame(width: 24, height: 24)
                    .background(urgencyLevel.color.opacity(0.1))
                    .clipShape(Circle())
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(isOverdue ? "OVERDUE" : "DUE IN")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(isOverdue ? 
                         "\(String(format: "%.1f", abs(timeUntilService))) hrs ago" : 
                         "\(String(format: "%.1f", timeUntilService)) hrs")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyLevel.color)
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
                            .fill(urgencyLevel.color)
                            .frame(width: 5, height: 5)
                        Text(urgencyLevel.statusText)
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
    
    private func getUrgencyLevel(timeUntilService: Double) -> UrgencyLevel {
        if timeUntilService <= 0 {
            return .overdue
        } else if timeUntilService <= 5 {
            return .urgent
        } else if timeUntilService <= 10 {
            return .warning
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
    case good, warning, urgent, overdue
    
    var color: Color {
        switch self {
        case .good:
            return .green
        case .warning:
            return .orange
        case .urgent:
            return .red
        case .overdue:
            return .red
        }
    }
    
    var statusText: String {
        switch self {
        case .good:
            return "Good"
        case .warning:
            return "Soon"
        case .urgent:
            return "Now"
        case .overdue:
            return "Overdue"
        }
    }
}

