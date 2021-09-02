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
  
  @Published var currentKeyframe: Int = 0
  @Published var isPlaying: Bool = false
  @Published var isEditingText: Bool = false
  @Published var selectedTrackerIndex: Int?
  @Published var isExportingVideo = false
  @Published var showExportingVideoModal = false
  @Published var exportedAssetURL: URL?
  @Published var lastActionDescription: String?

  var clearLastActionDescriptionTimer: Timer?
  
  var previewUntilFrame: Int?
  
  var videoPlayer: VideoPlayer
  var videoExporter = VideoExporter()
  
  var cancellables = Set<AnyCancellable>()
  
  init(document: Document) {
    self.document = document
    
    if document.trackers.count > 0 {
      selectedTrackerIndex = 0
    }
    
    self.videoPlayer = VideoPlayer()
    self.videoPlayer.delegate = self
    
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
          videoPlayer.seek(to: keyframe, fps:document.fps)
        }
      }.store(in: &cancellables)
    
    $currentKeyframe.sink { [weak self] frame in
      guard
        let self = self,
        let previewUntilFrame = self.previewUntilFrame else { return }
      if frame >= previewUntilFrame {
        self.isPlaying = false
        self.previewUntilFrame = nil
      }
    }.store(in: &cancellables)
    
    $document
      .map { $0.mediaURL }
      .removeDuplicates()
      .sink {[videoPlayer] url in videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))}
      .store(in: &cancellables)
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
  
  func exportVideo() {
    isExportingVideo = true
    withAnimation {
      showExportingVideoModal = true
    }
    exportedAssetURL = nil
    videoExporter
      .export(document: document)
      .mapError { $0 as Error }
      .receive(on: RunLoop.main)
      .sink { [weak self] completion in
        self?.isExportingVideo = false
      } receiveValue: {[weak self] url in
        self?.showExportingVideoModal = false
        DispatchQueue.main.async {
          let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
      }.store(in: &cancellables)
  }
}

extension VideoEditorViewModel {
  static var preview: VideoEditorViewModel {
    VideoEditorViewModel(document: Document.loadPreviewDocument())
  }
}

extension VideoEditorViewModel: MediaPlayerDelegate {
  func mediaPlayerDidPlayToTime(time: CMTime, duration: CMTime) {
    guard time.isNumeric && time.isValid else {
      return
    }
    let notRoundedFrameIndex = Double(time.value) / (Double(time.timescale) / Double(document.fps))
    if notRoundedFrameIndex.isFinite {
      currentKeyframe = min(Int(notRoundedFrameIndex.rounded(.toNearestOrAwayFromZero)), document.numberOfKeyframes - 1)
    }
  }
  
  func mediaPlayerDidPlayToEnd() {
    isPlaying = false
  }
}

protocol Help {
  func toastText() -> String
}

extension VideoEditorViewModel {
  private func addTracker() {
    let animation = Animation<CGPoint>(id: UUID(),
                                       keyframes: [currentKeyframe: CGPoint(x: 0.5, y: 0.5)],
                                       key: "position")
    let tracker = Tracker(id: UUID(), text: "Tracker \(document.trackers.count + 1)", position: animation)
    document.trackers.append(tracker)
    selectedTrackerIndex = document.trackers.count - 1
    isEditingText = true
  }
  
  private func removeSelectedTracker() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index {
      selectedTrackerIndex = nil
      document.trackers.remove(at: index)
    }
  }
  
  private func deleteCurrentKeyframe() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index,
       document.trackers[index].position.keyframes.keys.contains(currentKeyframe) {
      document.trackers[index].position.keyframes.removeValue(forKey: currentKeyframe)
      if document.trackers[index].position.keyframes.keys.contains(currentKeyframe + 1) {
        currentKeyframe = min(currentKeyframe + 1, document.numberOfKeyframes - 1)
      }
    }
  }
  
  private func duplicateCurrentKeyframe() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index,
       currentKeyframe < document.numberOfKeyframes,
       let value = document.trackers[index].position.keyframes[currentKeyframe] {
      document.trackers[index].position.keyframes[currentKeyframe + 1] = value
      currentKeyframe += 1
    }
  }
  
  private func goBack(frames: Int) {
    isPlaying = false
    currentKeyframe = max(0, currentKeyframe - frames)
  }
  
  private func goForward(frames: Int) {
    isPlaying = false
    currentKeyframe = min(document.numberOfKeyframes - 1, currentKeyframe + frames)
  }
  
  private func preview() {
    if currentKeyframe == 0 { return }
    let previewFrames = 10
    previewUntilFrame = currentKeyframe
    goBack(frames: previewFrames)
    isPlaying = true
  }
}

extension VideoEditorViewModel {
  enum Action {
    case addTracker
    case deleteCurrentKeyframe
    case duplicateCurrentKeyframe
    case goBack(frames: Int)
    case goForward(frames: Int)
    case removeSelectedTracker
    case play
    case pause
    case preview
    case editTracker
  }
  
  func submit(action: Action) {
    switch action {
    case .addTracker:
      addTracker()
    case .deleteCurrentKeyframe:
      deleteCurrentKeyframe()
    case .duplicateCurrentKeyframe:
      duplicateCurrentKeyframe()
    case .goBack(frames: let frames):
      goBack(frames: frames)
    case .goForward(frames: let frames):
      goForward(frames: frames)
    case .removeSelectedTracker:
      removeSelectedTracker()
    case .play:
      isPlaying = true
    case .pause:
      isPlaying = false
    case .preview:
      preview()
    case .editTracker:
      if let _ = selectedTrackerIndex {
        isEditingText = true
      }
    }
    showLastActionDescription(text: action.toastText())
  }
  
  func showLastActionDescription(text: String) {
    lastActionDescription = text
    clearLastActionDescriptionTimer?.invalidate()
    clearLastActionDescriptionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
      self?.lastActionDescription = nil
    })
  }
}

extension VideoEditorViewModel.Action: Help {
  func toastText() -> String {
    switch self {
    case .addTracker:
      return "Tracker added"
    case .deleteCurrentKeyframe:
      return "Keyframe deleted"
    case .duplicateCurrentKeyframe:
      return "Keyframe duplicated"
    case .goBack(frames: let frames):
      return "Moved back \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
    case .goForward(frames: let frames):
      return "Moved forward \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
    case .removeSelectedTracker:
      return "Tracker deleted"
    case .play:
      return "Playback started"
    case .pause:
      return "Playback paused"
    case .preview:
      return "Playing preview"
    case .editTracker:
      return "Editing tracker"
    }
  }
}
