//
//  ViewModelFactory.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import Foundation

/// Protocol defining factory methods for creating ViewModels
protocol ViewModelFactory {
    /// Creates a HomeViewModel instance
    func makeHomeViewModel() -> HomeViewModel
    
    /// Creates a VideoEditorViewModel instance with the given document
    func makeVideoEditorViewModel(document: Document) -> VideoEditorViewModel
}

/// Concrete implementation of ViewModelFactory that creates ViewModels with proper dependencies
class AppViewModelFactory: ViewModelFactory {
    private let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer = DependencyContainer.shared) {
        self.dependencyContainer = dependencyContainer
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(documentsService: dependencyContainer.resolve())
    }
    
    @MainActor func makeVideoEditorViewModel(document: Document) -> VideoEditorViewModel {
        return VideoEditorViewModel(
            document: document,
            documentService: dependencyContainer.resolve(),
            videoExporter: dependencyContainer.resolve()
        )
    }
}
