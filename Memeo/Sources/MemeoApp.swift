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
    @StateObject private var coordinator: AppCoordinator
    
    init() {
        // Configure third-party services
        FirebaseApp.configure()
        Giphy.configure(apiKey: "Y1yEr5cD6XeiWadQrhG7BpoQZMDmQYe8")
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_yOZceRdNqzNTNLHDYaPsyqTWeTM")
        
        // Set up dependency container
        let dependencyContainer = DependencyContainer.shared
        
        // Register services
        dependencyContainer.register(DocumentsService())
        dependencyContainer.register(VideoExporter())
        
        // Create factory and coordinator
        let viewModelFactory = AppViewModelFactory(dependencyContainer: dependencyContainer)
        let coordinator = AppCoordinator(viewModelFactory: viewModelFactory)
        
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Rectangle().fill(Color.black).ignoresSafeArea()
                Home(openUrl: $coordinator.openUrl, viewModel: coordinator.homeViewModel, coordinator: coordinator)
            }
            .onOpenURL(perform: { url in
                coordinator.handleOpenURL(url: url)
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
