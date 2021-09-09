//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

@main
struct MemeoApp: App {
  @State var openUrl: URL?

  init() {
    GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["120295e57b98a68268ffc522c0333e45"]
  }

  func requestIDFA() {
    ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
      GADMobileAds.sharedInstance().start(completionHandler: nil)
    })
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Rectangle().fill(Color.black).ignoresSafeArea()
        Home(openUrl: $openUrl)
      }
      .onOpenURL(perform: { url in
        openUrl = url
      })
      .onAppear() {
        requestIDFA()
      }
      .colorScheme(.dark)
    }
  }
}
