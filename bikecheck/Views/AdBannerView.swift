//
//  AdBannerView.swift
//  bikecheck
//
//  Created for AdMob integration - Issue #26
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    @State private var bannerView = BannerView()
    
    func makeUIView(context: Context) -> BannerView {
        // Test Ad Unit ID - replace with your real one when you create AdMob account
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        // Set banner size
        bannerView.adSize = AdSizeBanner
        
        // Set the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // Load the ad
        let request = Request()
        uiView.load(request)
    }
}

// MARK: - Preview
struct AdBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AdBannerView()
            .frame(height: 50)
            .previewLayout(.sizeThatFits)
    }
}
