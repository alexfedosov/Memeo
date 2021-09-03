//
//  HomeViewModel.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI
import Combine

struct HomeViewTemplatePreview: Identifiable, Hashable {
  var id: UUID
  var mediaURL: URL
  var aspectRatio: CGSize
}

class HomeViewModel: ObservableObject {
  @Published var selectedAssetUrl: URL? = nil
  
  @Published var videoEditorViewModel: VideoEditorViewModel? = nil
  @Published var showVideoEditor = false
  @Published var isImportingTemplate = false
  @Published var templates: [HomeViewTemplatePreview] = []
  
  var cancellables = Set<AnyCancellable>()
  
  init() {
    $selectedAssetUrl
      .compactMap { $0 }
      .flatMap { DocumentsService().create(from: $0) }
      .compactMap { VideoEditorViewModel(document: $0) }
      .replaceError(with: nil)
      .assign(to: \.videoEditorViewModel, on: self)
      .store(in: &cancellables)
    
    $videoEditorViewModel
      .compactMap { $0 != nil }
      .assign(to: \.showVideoEditor, on: self)
      .store(in: &cancellables)
    
    discoverTemplates()
  }
  
  func importTemplate(url: URL) {
    isImportingTemplate = true
    DocumentsService()
      .importDocument(url: url)
      .subscribe(on: DispatchQueue.global(qos: .background))
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: {[weak self] completion in
        self?.isImportingTemplate = false
        self?.discoverTemplates()
      }) {[weak self] doc in
        self?.videoEditorViewModel = VideoEditorViewModel(document: doc)
      }
      .store(in: &cancellables)
  }
  
  func discoverTemplates() {
    DocumentsService()
      .listStoredTemplates()
      .map { documents in
        documents.compactMap { doc in
          guard let url = doc.mediaURL else { return nil }
          return HomeViewTemplatePreview(id: doc.uuid, mediaURL: url, aspectRatio: doc.frameSize)
        }
      }
      .assign(to: \.templates, on: self)
      .store(in: &cancellables)
  }
  
  func openTemplate(uuid: UUID) {
    DocumentsService()
      .listStoredTemplates()
      .compactMap { documents in
        documents.filter { $0.uuid == uuid }.first
      }
      .compactMap { VideoEditorViewModel(document: $0) }
      .replaceError(with: nil)
      .assign(to: \.videoEditorViewModel, on: self)
      .store(in: &cancellables)
  }
}
