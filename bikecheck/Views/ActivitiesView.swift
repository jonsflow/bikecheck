import SwiftUI

struct ActivitiesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ActivitiesViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.activities.isEmpty {
                    Text("No activities found")
                } else {
                    List {
                        ForEach(viewModel.activities, id: \.self) { activity in
                            ActivityCardView(activity: activity, viewModel: viewModel)
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
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: ProfileImageView())
            .onAppear {
                viewModel.loadActivities()
            }
        }
    }
    
}

struct ActivityCardView: View {
    let activity: Activity
    let viewModel: ActivitiesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.getBikeName(for: activity))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Duration")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(viewModel.getFormattedDuration(for: activity))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Distance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(viewModel.getFormattedDistance(for: activity))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Date")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text(viewModel.getFormattedDate(for: activity))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
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

