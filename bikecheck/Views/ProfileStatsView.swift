import SwiftUI

struct ProfileStatsView: View {
    @StateObject private var viewModel = ProfileStatsViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bike Nerd Stats")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                StatTile(icon: "bicycle", value: "\(viewModel.bikeCount)", label: "Bikes")
                StatTile(icon: "mappin.and.ellipse", value: formatMiles(viewModel.totalMiles), label: "Miles")
                StatTile(icon: "clock", value: formatHours(viewModel.totalHours), label: "Hours Ridden")
                StatTile(icon: "figure.outdoor.cycle", value: "\(viewModel.activityCount)", label: "Activities")
                StatTile(icon: "wrench.and.screwdriver", value: "\(viewModel.partsTracked)", label: "Parts Tracked")
                StatTile(
                    icon: "exclamationmark.triangle",
                    value: "\(viewModel.overdueCount)",
                    label: "Overdue",
                    valueColor: viewModel.overdueCount > 0 ? .red : .primary
                )
                StatTile(icon: "checkmark.seal", value: "\(viewModel.servicesLogged)", label: "Services Logged")
            }
            .padding(.horizontal)
        }
        .onAppear { viewModel.load() }
    }

    private func formatMiles(_ miles: Double) -> String {
        if miles >= 1000 {
            return String(format: "%.1fk", miles / 1000)
        }
        return String(format: "%.0f", miles)
    }

    private func formatHours(_ hours: Double) -> String {
        if hours >= 1000 {
            return String(format: "%.1fk", hours / 1000)
        }
        return String(format: "%.0f", hours)
    }
}

private struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(valueColor)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
