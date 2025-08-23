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
            
            VStack(spacing: 12) {
                Text("Your Ad Here")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("Promote your cycling business or product")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
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