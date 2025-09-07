//
//  GiphyView.swift
//  Memeo
//
//  Created by Alex on 10.9.2021.
//  Moved to Features/Home structure
//

import Combine
import GiphyUISDK
import SwiftUI

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
        if context.coordinator.prevSearchString != searchQuery {
            if searchQuery.count > 0 {
                uiViewController.content = GPHContent.search(
                    withQuery: searchQuery, mediaType: .gif, language: .english)
            } else {
                uiViewController.content = .trendingGifs
                uiViewController.rating = .ratedG
            }
            uiViewController.update()
        }
        context.coordinator.prevSearchString = searchQuery
    }

    class Coordinator: NSObject, GPHGridDelegate {
        var selectedMedia: Binding<GPHMedia?>
        var searchQuerySubject = PassthroughSubject<String?, Never>()
        var prevSearchString: String? = nil {
            didSet {
                searchQuerySubject.send(prevSearchString)
            }
        }

        var cancellable: AnyCancellable? = nil

        init(selectedMedia: Binding<GPHMedia?>) {
            self.selectedMedia = selectedMedia
            cancellable =
                searchQuerySubject
                .compactMap { $0 }
                .filter { $0.count > 0 }
                .receive(on: DispatchQueue.global())
                .debounce(for: 1, scheduler: DispatchQueue.global())
                .removeDuplicates()
                .sink(receiveValue: { _ in })
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
        GiphyView(searchQuery: .constant(""), selectedMedia: .constant(GPHMedia())).frame(
            maxWidth: .infinity, maxHeight: .infinity)
    }
}
