//
//  HomeViewModel.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
  @Published var selectedAssetUrl: URL? = nil
  @Published var videoEditorViewModel: VideoEditorViewModel? = nil
  
  var cancellable = Set<AnyCancellable>()
  
  init() {
    $selectedAssetUrl
      .compactMap { $0 }
      .flatMap { DocumentCreatorService().createDocument(from: $0) }
      .compactMap { $0 }
      .compactMap { [weak self] in
        let model = VideoEditorViewModel(document: $0.0, asset: $0.1)
        model.assetURL = self?.selectedAssetUrl
        return model
      }
      .replaceError(with: nil)
      .assign(to: \.videoEditorViewModel, on: self)
      .store(in: &cancellable)
  }
}
