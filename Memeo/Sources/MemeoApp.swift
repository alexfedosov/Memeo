//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import GiphyUISDK
import SwiftUI

@main
struct MemeoApp: App {
    @StateObject private var coordinator: AppCoordinator
    private let logger = Logger.shared

    init() {
        Giphy.configure(apiKey: "")

        Logger.shared.logAppLifecycle("App initialized", details: ["version": UIApplication.appVersion ?? "unknown"])

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
                logger.logUserInteraction("Open URL", details: ["url": url.absoluteString])
                coordinator.handleOpenURL(url: url)
            })
            .colorScheme(.dark)
        }
    }
}
