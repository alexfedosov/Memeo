//
//  FullscreenAdModifier.swift
//  Memeo
//
//  Created by Alex on 8.9.2021.
//

import Foundation
import SwiftUI

struct FullscreenAdModifier: ViewModifier {
  var adUnitId: String
  
  @Binding var isPresented: Bool
  
  func body(content: Content) -> some View {
    content
      .onAppear {
        InterstitialAd.shared.loadAd(withAdUnitId: adUnitId)
      }
      .fullScreenCover(isPresented: $isPresented) {
        InterstitialAdView(isPresented: $isPresented, adUnitId: adUnitId)
      }
  }
}

extension View {
  public func presentInterstitialAd(isPresented: Binding<Bool>, adUnitId: String) -> some View {
    self.modifier(FullscreenAdModifier(adUnitId: adUnitId, isPresented: isPresented))
  }
}
