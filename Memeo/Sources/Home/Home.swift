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
    if let document = model.document {
      VideoEditor(viewModel: VideoEditorViewModel(document: document))
    } else {
      UploadVideoView(mediaURL: $model.mediaURL)
    }
  }
}

struct Home_Previews: PreviewProvider {
  static var previews: some View {
    Home()
  }
}
