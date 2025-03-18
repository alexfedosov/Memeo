//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Firebase
import GiphyUISDK
import SwiftUI
import RevenueCat
import RevenueCatUI
import FirebaseAnalytics

@main
struct MemeoApp: App {
    @State var openUrl: URL?

    init() {
        FirebaseApp.configure()
        Giphy.configure(apiKey: "Y1yEr5cD6XeiWadQrhG7BpoQZMDmQYe8")
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_yOZceRdNqzNTNLHDYaPsyqTWeTM")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Rectangle().fill(Color.black).ignoresSafeArea()
                Home(openUrl: $openUrl, viewModel: HomeViewModel())
            }
            .onOpenURL(perform: { url in
                openUrl = url
            })
            .colorScheme(.dark)
            .presentPaywallIfNeeded(
                requiredEntitlementIdentifier: "pro",
                purchaseCompleted: { customerInfo in
                    print("Purchase completed: \(customerInfo.entitlements)")
                    Analytics.logEvent(
                        AnalyticsEventPurchase,
                        parameters: [
                            AnalyticsParameterDestination: "Unlock Pro"
                        ])
                },
                restoreCompleted: { customerInfo in
                }
            )
        }
    }
}
