//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI

@main
struct MemeoApp: App {
  @ObservedObject var videoEditoViewModel = VideoEditorViewModel(document: Document.loadPreviewDocument())
  
  var body: some Scene {
    WindowGroup {
      HomeView(viewModel: videoEditoViewModel)
    }
  }
}
