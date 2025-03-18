//
//  HomeViewModel.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import GiphyUISDK
import SwiftUI


enum Source {
    case url(URL)
    case image(UIImage)
    case giphy(GPHMedia)
}

@MainActor
class HomeViewModel: ObservableObject {
    // Published properties with private(set) for state
    @Published private(set) var videoEditorViewModel: VideoEditorViewModel? = nil
    @Published private(set) var isImportingVideo = false
    @Published private(set) var documents: [Document] = []
    @Published private(set) var error: Error? = nil
    
    private let documentsService: DocumentsService
    
    init(documentsService: DocumentsService = DocumentsService()) {
        self.documentsService = documentsService
        Task {
            await loadDocuments()
        }
    }
    
    func create(from source: Source) async {
        isImportingVideo = true
        error = nil
        do {
            let document = switch source {
            case .url(let url): try await documentsService.create(fromMedia: url)
            case .image(let image): try await documentsService.create(fromImage: image)
            case .giphy(let giphy): try await documentsService.create(fromGIPHY: giphy)
            }
            setVideoEditorViewModel(VideoEditorViewModel(document: document))
        } catch {
            self.error = error
        }
        isImportingVideo = false
    }
    
    private func loadDocuments() async {
        do {
            // This would be the implementation if DocumentsService had a loadDocuments method
            // documents = try await documentsService.loadDocuments()
        } catch {
            self.error = error
        }
    }
    
    // Methods to modify state
    func setVideoEditorViewModel(_ viewModel: VideoEditorViewModel?) {
        videoEditorViewModel = viewModel
    }
}
