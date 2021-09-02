//
//  Home.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import SwiftUI

struct Home: View {
  @ObservedObject var model = HomeViewModel()
  
  var body: some View {
    if let videoEditorViewModel = model.videoEditorViewModel {
      VideoEditor(viewModel: videoEditorViewModel) {
        model.videoEditorViewModel = nil
      }
    } else {
      UploadVideoView(mediaURL: $model.selectedAssetUrl)
    }
  }
}

struct Home_Previews: PreviewProvider {
  static var previews: some View {
    Home()
  }
}
