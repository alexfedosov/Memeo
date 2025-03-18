//
//  Coordinator.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import Foundation
import SwiftUI

/// App Coordinator that manages navigation state and ViewModel creation
@MainActor
class AppCoordinator: ObservableObject {
    @Published var openUrl: URL?
    @Published var homeViewModel: HomeViewModel
    
    private let viewModelFactory: ViewModelFactory
    
    init(viewModelFactory: ViewModelFactory) {
        self.viewModelFactory = viewModelFactory
        self.homeViewModel = viewModelFactory.makeHomeViewModel()
    }
    
    func handleOpenURL(url: URL) {
        openUrl = url
    }
    
    func createVideoEditorViewModel(document: Document) -> VideoEditorViewModel {
        return viewModelFactory.makeVideoEditorViewModel(document: document)
    }
}