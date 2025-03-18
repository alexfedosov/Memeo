//
//  EnvironmentValues.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import SwiftUI

// MARK: - ViewModels Environment

// We'll use EnvironmentObject instead of custom Environment Keys
// since it's more straightforward for this purpose and better supported

// MARK: - ViewModel Extension Methods

extension View {
    /// Adds a VideoEditorViewModel to the environment
    /// - Parameter viewModel: The VideoEditorViewModel to add
    /// - Returns: A view with the VideoEditorViewModel in its environment
    func withVideoEditorViewModel(_ viewModel: VideoEditorViewModel) -> some View {
        environmentObject(viewModel)
    }
    
    /// Adds a HomeViewModel to the environment
    /// - Parameter viewModel: The HomeViewModel to add
    /// - Returns: A view with the HomeViewModel in its environment
    func withHomeViewModel(_ viewModel: HomeViewModel) -> some View {
        environmentObject(viewModel)
    }
}