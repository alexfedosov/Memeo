//
// Created by Alex on 9.9.2021.
//

import Foundation
import Combine
import SwiftUI
import MobileCoreServices
import AVKit

class ShareViewModel: ObservableObject {
  var isShown: Binding<Bool>
  var videoPlayer: VideoPlayer?
  let muted: Bool
  let frameSize: CGSize
  let videoUrl: URL?
  let gifURL: URL?

  var bag = Set<AnyCancellable>()

  init(isShown: Binding<Bool>, videoUrl: URL?, gifURL: URL?, frameSize: CGSize, muted: Bool) {
    self.isShown = isShown
    self.videoUrl = videoUrl
    self.gifURL = gifURL
    self.frameSize = frameSize
    self.muted = muted

    if let videoUrl = videoUrl, isShown.wrappedValue {
      videoPlayer = VideoPlayer()
      videoPlayer?.replaceCurrentItem(with: AVPlayerItem(url: videoUrl))
      videoPlayer?.shouldAutoRepeat = true
      videoPlayer?.isMuted = muted
      videoPlayer?.play()
    }
  }

  func copyGifToPasteboard() {
    guard let gifURL = gifURL else {
      return
    }

    do {
      let data = try Data(contentsOf: gifURL)
      UIPasteboard.general.setData(data, forPasteboardType: kUTTypeGIF as String)
    } catch {
      print("Could not copy gif to clipboard")
    }
  }

  func showMoreSharingOptions() {
    guard let videoUrl = videoUrl else {
      return
    }
    let activityVC = UIActivityViewController(activityItems: [videoUrl], applicationActivities: nil)
    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: { [weak self] in
      self?.closeShareDialog()
    })
  }

  func shareToInstagram() {
    guard let videoUrl = videoUrl else {
      return
    }

    VideoExporter()
      .moveAssetToMemeoAlbum(url: videoUrl)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { _ in },
        receiveValue: { localIdentifier in
          guard let localIdentifier = localIdentifier else {
            return
          }
          let urlString = "instagram://library?LocalIdentifier=" + localIdentifier
          guard let url = URL(string: urlString),
                UIApplication.shared.canOpenURL(url) else {
            return
          }
          UIApplication.shared.open(url)
        })
      .store(in: &bag)
  }

  func saveToPhotoLibrary() {
    guard let videoUrl = videoUrl else {
      return
    }

    VideoExporter()
      .moveAssetToMemeoAlbum(url: videoUrl)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { _ in },
        receiveValue: { _ in })
      .store(in: &bag)
  }

  func closeShareDialog() {
    videoPlayer?.unload()
    withAnimation {
      isShown.wrappedValue = false
    }
  }
}

