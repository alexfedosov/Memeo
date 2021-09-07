//
//  HomeViewModel.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI
import Combine

struct TemplatePreview: Identifiable, Hashable {
  var id: UUID
  var previewUrl: URL?
  var aspectRatio: CGSize
}

class HomeViewModel: ObservableObject {
  @Published var selectedAssetUrl: URL? = nil
  
  @Published var videoEditorViewModel: VideoEditorViewModel? = nil
  @Published var showVideoEditor = false
  @Published var isImportingTemplate = false
  @Published var isImportingVideo = false
  @Published var templates: [TemplatePreview] = []
  
  var cancellables = Set<AnyCancellable>()
  
  init() {
    $selectedAssetUrl
      .compactMap { $0 }
      .map { _ in true }
      .assign(to: \.isImportingVideo, on: self)
      .store(in: &cancellables)
    
    $selectedAssetUrl
      .receive(on: DispatchQueue.global())
      .compactMap { $0 }
      .flatMap { DocumentsService().create(from: $0) }
      .receive(on: DispatchQueue.global())
      .flatMap { DocumentsService().save(document: $0) }
      .receive(on: DispatchQueue.global())
      .flatMap { DocumentsService().load(url: $0) }
      .receive(on: DispatchQueue.global())
      .compactMap {
        VideoEditorViewModel(document: $0)
      }
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { _ in },
      receiveValue: {[weak self] model in
        self?.isImportingVideo = false
        self?.videoEditorViewModel = model
      })
      .store(in: &cancellables)
    
    $videoEditorViewModel
      .compactMap {
        $0 != nil
      }
      .assign(to: \.showVideoEditor, on: self)
      .store(in: &cancellables)
    
    discoverTemplates()
  }
  
  func importTemplate(url: URL) {
    isImportingTemplate = true
    DocumentsService()
      .importDocument(url: url)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { [weak self] completion in
        self?.isImportingTemplate = false
        self?.discoverTemplates()
      }) { [weak self] doc in
        self?.videoEditorViewModel = VideoEditorViewModel(document: doc)
      }
      .store(in: &cancellables)
  }
  
  func discoverTemplates() {
    Just(())
      .receive(on: DispatchQueue.global())
      .flatMap {
        DocumentsService()
          .listStoredTemplates()
          .map { documents in
            documents.compactMap { doc in
              return TemplatePreview(id: doc.uuid, previewUrl: doc.previewURL, aspectRatio: doc.frameSize)
            }
          }
      }
      .receive(on: DispatchQueue.main)
      .assign(to: \.templates, on: self)
      .store(in: &cancellables)
  }
  
  func openTemplate(uuid: UUID) {
    Just(())
      .receive(on: DispatchQueue.global())
      .flatMap {
        DocumentsService()
          .listStoredTemplates()
          .compactMap { documents in
            documents.filter {
              $0.uuid == uuid
            }.first
          }
          .compactMap {
            VideoEditorViewModel(document: $0)
          }
          .replaceError(with: nil)
      }
      .receive(on: DispatchQueue.main)
      .assign(to: \.videoEditorViewModel, on: self)
      .store(in: &cancellables)
  }
}
