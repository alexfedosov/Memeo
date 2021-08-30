//
//  VideoEditorViewModel.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

class VideoEditorViewModel: ObservableObject {
  @Published var document: Document
  @Published var asset: AVAsset
  @Published var currentKeyframe: Int = 0
  @Published var isPlaying: Bool = false
  @Published var isEditingText: Bool = false
  @Published var selectedTrackerIndex: Int?
  var videoPlayer: VideoPlayer
  
  var cancellables = Set<AnyCancellable>()
  
  init(document: Document, asset: AVAsset) {
    self.document = document
    if document.trackers.count > 0 {
      selectedTrackerIndex = 0
    }
    self.asset = asset
    self.videoPlayer = VideoPlayer()
    self.videoPlayer.delegate = self
    videoPlayer.replaceCurrentItem(with: AVPlayerItem(asset: asset))
    $isPlaying.sink { [videoPlayer] isPlaying in
      if isPlaying {
        videoPlayer.play()
      } else {
        videoPlayer.pause()
      }
    }.store(in: &cancellables)
    
    
    Publishers.CombineLatest($currentKeyframe, $isPlaying)
      .sink { [videoPlayer] keyframe, isPlaying in
        if !isPlaying {
          videoPlayer.seek(to: keyframe, fps: 10)
        }
      }.store(in: &cancellables)
  }
  
  func addTracker() {
    let animation = Animation<CGPoint>(id: UUID(),
                                       keyframes: [currentKeyframe: CGPoint(x: 0.5, y: 0.5)],
                                       key: "position")
    let tracker = Tracker(id: UUID(), text: "Tracker \(document.trackers.count + 1)", position: animation)
    document.trackers.append(tracker)
    selectedTrackerIndex = document.trackers.count - 1
  }
  
  func removeSelectedTracker() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index {
      selectedTrackerIndex = nil
      document.trackers.remove(at: index)
    }
  }
  
  func selectTracker(tracker: Tracker) {
    selectedTrackerIndex = document.trackers.firstIndex(of: tracker)
  }
  
  func changePositionKeyframeValue(tracker: Tracker, point: CGPoint) {
    guard let index = document.trackers.firstIndex(of: tracker) else { return }
    if selectedTrackerIndex != index {
      selectedTrackerIndex = index
    }
    document.trackers[index].position.keyframes[currentKeyframe] = point
  }
  
  func deleteCurrentKeyframe() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index,
       document.trackers[index].position.keyframes.keys.contains(currentKeyframe) {
      document.trackers[index].position.keyframes.removeValue(forKey: currentKeyframe)
      if document.trackers[index].position.keyframes.keys.contains(currentKeyframe + 1) {
        currentKeyframe = min(currentKeyframe + 1, document.numberOfKeyframes - 1)
      }
    }
  }
  
  func duplicateCurrentKeyframe() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index,
       currentKeyframe < document.numberOfKeyframes,
       let value = document.trackers[index].position.keyframes[currentKeyframe] {
      document.trackers[index].position.keyframes[currentKeyframe + 1] = value
      currentKeyframe += 1
    }
  }
}

extension VideoEditorViewModel {
  static var preview: VideoEditorViewModel {
    let url = Bundle.main.url(forResource: "previewAsset", withExtension: "mp4")!
    let asset = AVAsset(url: url)
    return VideoEditorViewModel(document: Document.loadPreviewDocument(), asset: asset)
  }
}

extension VideoEditorViewModel: MediaPlayerDelegate {
  func mediaPlayerDidPlayToTime(time: CMTime, duration: CMTime) {
    guard time.isNumeric && time.isValid else {
      return
    }
    let notRoundedFrameIndex = Double(time.value) / (Double(time.timescale) / Double(10))
    if notRoundedFrameIndex.isFinite {
      currentKeyframe = Int(notRoundedFrameIndex.rounded(.toNearestOrAwayFromZero))
    }
  }
  
  func mediaPlayerDidPlayToEnd() {
    isPlaying = false
  }
}
