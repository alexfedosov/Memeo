//
// Created by Alex on 7.8.2021.
//

import Foundation
import AVFoundation
import SwiftUI
import UIKit

class AVPlayerLayerView: UIView {
  let playerLayer: AVPlayerLayer

  override init(frame: CGRect) {
    playerLayer = AVPlayerLayer(player: nil)
    playerLayer.videoGravity = .resizeAspect
    super.init(frame: frame)
    layer.addSublayer(playerLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }
}


struct VideoPlayerView: UIViewRepresentable {
  let videoPlayer: VideoPlayer

  func makeUIView(context: Context) -> AVPlayerLayerView {
    let view = AVPlayerLayerView(frame: .zero)
    view.playerLayer.player = videoPlayer
    return view
  }

  func updateUIView(_ uiView: AVPlayerLayerView, context: Context) {
    if uiView.playerLayer.player != videoPlayer {
      uiView.playerLayer.player = videoPlayer
    }
  }
}
