import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("BikeCheckLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .cornerRadius(30)

            ProgressView()
                .scaleEffect(1.5)
        }
    }
}
