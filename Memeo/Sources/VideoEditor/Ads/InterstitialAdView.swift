//
//  SwiftUIView.swift
//  Memeo
//
//  Created by Alex on 8.9.2021.
//


import SwiftUI
import GoogleMobileAds
import UIKit

class InterstitialAd: NSObject {
  static let adUnit = "ca-app-pub-5900049420163800/9442856811"
  static let testAdUnit = "ca-app-pub-3940256099942544/4411468910"
  
  static let shared = InterstitialAd()
  
  var interstitialAd: GADInterstitialAd?
  
  func loadAd(withAdUnitId id: String) {
    let req = GADRequest()
    GADInterstitialAd.load(withAdUnitID: id, request: req) { interstitialAd, err in
      if let err = err {
        print("Failed to load ad with error: \(err)")
        return
      }
      
      self.interstitialAd = interstitialAd
    }
  }
}

struct InterstitialAdView: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  let adUnitId: String
  
  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
      context.coordinator.showAd(from: viewController)
    }
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    context.coordinator.adUnitId = adUnitId
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(isPresented: $isPresented)
  }

  class Coordinator: NSObject, GADFullScreenContentDelegate {
    var isPresented: Binding<Bool>
    var adUnitId: String = ""

    init(isPresented: Binding<Bool>) {
      self.isPresented = isPresented
      super.init()
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
      InterstitialAd.shared.loadAd(withAdUnitId: adUnitId)
      isPresented.wrappedValue = false
    }
    
    func showAd(from root: UIViewController) {
      if let ad = InterstitialAd.shared.interstitialAd,
         let _  = try? ad.canPresent(fromRootViewController: root) {
        ad.fullScreenContentDelegate = self
        ad.present(fromRootViewController: root)
      } else {
        print("Ad not ready")
        isPresented.wrappedValue = false
      }
    }
  }
}

struct AdPreview: View {
  @State var isPresented = false
  var body: some View {
    VStack {
      Text("Hello")
      Button("Show Ad") { isPresented = true }
    }.presentInterstitialAd(isPresented: $isPresented, adUnitId: InterstitialAd.adUnit)
  }
}

struct InterstitialAdView_Previews: PreviewProvider {
  static var previews: some View {
    AdPreview()
  }
}
