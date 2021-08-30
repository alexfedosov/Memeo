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
  @Published var mediaURL: URL? = nil
  @Published var document: Document? = nil
  
  var cancellable = Set<AnyCancellable>()
  
  init() {
    $mediaURL
      .compactMap { $0 }
      .flatMap { DocumentCreatorService().createDocument(from: $0) }
      .compactMap { $0 }
      .sink(receiveCompletion: { _ in
        
      }, receiveValue: {[weak self] document in
        self?.document = document
      })
      .store(in: &cancellable)
  }
}
