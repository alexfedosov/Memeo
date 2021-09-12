//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI
import GoogleMobileAds
import GiphyUISDK
import Firebase

@main
struct MemeoApp: App {
  @State var openUrl: URL?

  init() {
    FirebaseApp.configure()
//    GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["120295e57b98a68268ffc522c0333e45"]
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    Giphy.configure(apiKey: "Y1yEr5cD6XeiWadQrhG7BpoQZMDmQYe8")
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
      .colorScheme(.dark)
    }
  }
}
