import SwiftUI

struct AdContainerView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Advertisement")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // AdMob Banner Ad
            AdBannerView()
                .frame(height: 50)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}