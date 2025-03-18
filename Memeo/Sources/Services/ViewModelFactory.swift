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
    private let documentsService: DocumentsService
    
    init(documentsService: DocumentsService = DocumentsService()) {
        self.documentsService = documentsService
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(documentsService: documentsService)
    }
    
    @MainActor func makeVideoEditorViewModel(document: Document) -> VideoEditorViewModel {
        return VideoEditorViewModel(document: document)
    }
}
