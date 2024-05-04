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
    @Published var videoEditorViewModel: VideoEditorViewModel? = nil
    @Published var isImportingVideo = false

    func create(from source: Source) async {
        isImportingVideo = true
        do {
            let documentService = DocumentsService()
            let document = switch source {
            case .url(let url): try await documentService.create(fromMedia: url)
            case .image(let image): try await documentService.create(fromImage: image)
            case .giphy(let giphy): try await documentService.create(fromGIPHY: giphy)
            }
            videoEditorViewModel = VideoEditorViewModel(document: document)
        } catch {
            print(error)
        }
        isImportingVideo = false
    }
}
