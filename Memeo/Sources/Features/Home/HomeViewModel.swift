//
//  HomeViewModel.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//  Moved to Features/Home structure
//

import Foundation
import GiphyUISDK
import SwiftUI


enum Source {
    case url(URL)
    case image(UIImage)
    case giphy(GPHMedia)
}

class HomeViewModel: ObservableObject {
    // Published properties with private(set) for state
    @Published private(set) var videoEditorViewModel: VideoEditorViewModel? = nil
    @Published var isImportingVideo = false // Keep this mutable for binding
    @Published private(set) var documents: [Document] = []
    @Published private(set) var error: Error? = nil
    
    private let documentsService: DocumentsService
    
    init(documentsService: DocumentsService) {
        self.documentsService = documentsService
        Task { @MainActor in
            await loadDocuments()
        }
    }
    
    @MainActor
    func create(from source: Source, viewModelFactory: ((Document) -> VideoEditorViewModel)? = nil) async {
        isImportingVideo = true
        error = nil
        do {
            let document = switch source {
            case .url(let url): try await documentsService.create(fromMedia: url)
            case .image(let image): try await documentsService.create(fromImage: image)
            case .giphy(let giphy): try await documentsService.create(fromGIPHY: giphy)
            }
            
            if let factory = viewModelFactory {
                // Use the factory function provided by coordinator
                setVideoEditorViewModel(factory(document))
            } else {
                // Create services directly as a fallback
                let docService = DocumentsService()
                let videoExport = VideoExporter()
                setVideoEditorViewModel(VideoEditorViewModel(document: document, documentService: docService, videoExporter: videoExport))
            }
        } catch {
            self.error = error
        }
        isImportingVideo = false
    }
    
    @MainActor
    private func loadDocuments() async {
        do {
            // This would be the implementation if DocumentsService had a loadDocuments method
            // documents = try await documentsService.loadDocuments()
        } catch {
            self.error = error
        }
    }
    
    // Methods to modify state
    @MainActor
    func setVideoEditorViewModel(_ viewModel: VideoEditorViewModel?) {
        videoEditorViewModel = viewModel
    }
}
