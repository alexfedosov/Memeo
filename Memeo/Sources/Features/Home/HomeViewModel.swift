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
    private let logger = Logger.shared
    // Published properties with private(set) for state
    @Published private(set) var videoEditorViewModel: VideoEditorViewModel? = nil
    @Published var isImportingVideo = false // Keep this mutable for binding
    @Published private(set) var documents: [Document] = []
    @Published private(set) var error: Error? = nil
    
    private let documentsService: DocumentsService
    
    init(documentsService: DocumentsService) {
        self.documentsService = documentsService
        logger.info("HomeViewModel initialized", category: .viewModel)
        Task { @MainActor in
            await loadDocuments()
        }
    }
    
    @MainActor
    func create(from source: Source, viewModelFactory: ((Document) -> VideoEditorViewModel)? = nil) async {
        logger.info("Creating document from source: \(source)", category: .viewModel)
        isImportingVideo = true
        error = nil
        do {
            let document: Document
            switch source {
            case .url(let url):
                logger.info("Creating document from URL: \(url.lastPathComponent)", category: .viewModel)
                document = try await documentsService.create(fromMedia: url)
            case .image(let image):
                logger.info("Creating document from image", category: .viewModel)
                document = try await documentsService.create(fromImage: image)
            case .giphy(let giphy):
                logger.info("Creating document from GIPHY media: \(giphy.id)", category: .viewModel)
                document = try await documentsService.create(fromGIPHY: giphy)
            }
            
            if let factory = viewModelFactory {
                // Use the factory function provided by coordinator
                logger.info("Creating VideoEditorViewModel using factory for document: \(document.uuid)", category: .viewModel)
                setVideoEditorViewModel(factory(document))
            } else {
                // Create services directly as a fallback
                logger.warning("Creating VideoEditorViewModel without factory for document: \(document.uuid)", category: .viewModel)
                let docService = DocumentsService()
                let videoExport = VideoExporter()
                setVideoEditorViewModel(VideoEditorViewModel(document: document, documentService: docService, videoExporter: videoExport))
            }
            logger.info("Successfully created document: \(document.uuid)", category: .viewModel)
        } catch {
            logger.logError("Failed to create document from source", error: error, category: .viewModel)
            self.error = error
        }
        isImportingVideo = false
    }
    
    @MainActor
    private func loadDocuments() async {
        logger.info("Loading documents", category: .viewModel)
        do {
            // This would be the implementation if DocumentsService had a loadDocuments method
            // documents = try await documentsService.loadDocuments()
            // logger.info("Loaded \(documents.count) documents", category: .viewModel)
        } catch {
            logger.logError("Failed to load documents", error: error, category: .viewModel)
            self.error = error
        }
    }
    
    // Methods to modify state
    @MainActor
    func setVideoEditorViewModel(_ viewModel: VideoEditorViewModel?) {
        if let viewModel = viewModel {
            logger.info("Setting VideoEditorViewModel for document", category: .viewModel)
        } else {
            logger.info("Clearing VideoEditorViewModel", category: .viewModel)
        }
        videoEditorViewModel = viewModel
    }
}
