//
//  GiphyView.swift
//  Memeo
//
//  Created by Alex on 10.9.2021.
//

import SwiftUI
import GiphyUISDK

struct GiphyView: UIViewControllerRepresentable {
  @Binding var searchQuery: String
  @Binding var selectedMedia: GPHMedia?
  
  func makeCoordinator() -> Coordinator {
    Coordinator(selectedMedia: $selectedMedia)
  }
  
  func makeUIViewController(context: Context) -> GiphyGridController {
    let gridController = GiphyGridController()
    gridController.cellPadding = 4
    gridController.delegate = context.coordinator
    return gridController
  }
  
  func updateUIViewController(_ uiViewController: GiphyGridController, context: Context) {
    if (context.coordinator.prevSearchString != searchQuery) {
      if searchQuery.count > 0 {
        uiViewController.content = GPHContent.search(withQuery: searchQuery, mediaType: .gif, language: .english)
      } else {
        uiViewController.content = .trendingGifs
      }
      uiViewController.update()
    }
    context.coordinator.prevSearchString = searchQuery
  }

  class Coordinator: NSObject, GPHGridDelegate {
    var selectedMedia: Binding<GPHMedia?>
    var prevSearchString: String? = nil
    
    init(selectedMedia: Binding<GPHMedia?>) {
      self.selectedMedia = selectedMedia
    }
    
    @objc func didSelectMedia(media: GPHMedia, cell: UICollectionViewCell) {
      selectedMedia.wrappedValue = media
    }
    
    @objc func didScroll(offset: CGFloat) {}
    @objc func contentDidUpdate(resultCount: Int, error: Error?) {}
    @objc func didSelectMoreByYou(query: String) {}
  }
}


struct GiphyView_Previews: PreviewProvider {
  static var previews: some View {
    GiphyView(searchQuery: .constant(""), selectedMedia: .constant(GPHMedia())).frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
