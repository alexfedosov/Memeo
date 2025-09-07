//
// Created by Alex on 9.9.2021.
//

import AVKit
import Combine
import Foundation
import MobileCoreServices
import SwiftUI

class ShareViewModel: ObservableObject {
    var isShown: Binding<Bool>
    var videoPlayer: VideoPlayer?
    let muted: Bool
    let frameSize: CGSize
    let videoUrl: URL?
    let gifURL: URL?

    @Published var notification: String?

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

        $notification
            .print()
            .compactMap { $0 }
            .delay(for: 1.5, scheduler: RunLoop.main)
            .map { _ in nil }
            .assign(to: &$notification)
    }

    func copyGifToPasteboard() {
        guard let gifURL = gifURL else {
            return
        }

        do {
            let data = try Data(contentsOf: gifURL)
            UIPasteboard.general.setData(data, forPasteboardType: UTType.gif.identifier)
            notification = "Gif copied!"
        } catch {
            print("Could not copy gif to clipboard")
        }
    }

    func showMoreSharingOptions() {
        guard let videoUrl = videoUrl else {
            return
        }
        let activityVC = UIActivityViewController(activityItems: [videoUrl], applicationActivities: nil)
        UIApplication.shared.windows.first?
            .rootViewController?
            .present(activityVC, animated: true)
    }

    func shareToInstagram() {
        guard let videoUrl = videoUrl else {
            return
        }

        VideoExporter()
            .moveAssetToMemeoAlbum(url: videoUrl)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { localIdentifier in
                    guard let localIdentifier = localIdentifier else {
                        return
                    }
                    let urlString = "instagram://library?LocalIdentifier=" + localIdentifier
                    guard let url = URL(string: urlString),
                        UIApplication.shared.canOpenURL(url)
                    else {
                        return
                    }
                    UIApplication.shared.open(url)
                }
            )
            .store(in: &bag)
    }

    func saveToPhotoLibrary() {
        guard let videoUrl = videoUrl else {
            return
        }

        VideoExporter()
            .moveAssetToMemeoAlbum(url: videoUrl)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.notification = "Video saved!"
                },
                receiveValue: { _ in }
            )
            .store(in: &bag)
    }

    func closeShareDialog() {
        videoPlayer?.unload()
        withAnimation {
            isShown.wrappedValue = false
        }
    }
}
