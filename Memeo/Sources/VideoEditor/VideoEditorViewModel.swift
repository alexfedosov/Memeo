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
  let documentService = DocumentsService()

  @Published var document: Document

  @Published var currentKeyframe: Int = 0
  @Published var isPlaying: Bool = false
  @Published var isEditingText: Bool = false
  @Published var selectedTrackerIndex: Int?
  @Published var isExportingVideo = false
  @Published var showExportingVideoModal = false
  @Published var exportedAssetURL: URL?
  @Published var lastActionDescription: String?
  @Published var showExportingOptionsDialog = false

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

    videoPlayer = VideoPlayer()
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
          videoPlayer.seek(to: keyframe, fps: document.fps)
        }
      }.store(in: &cancellables)

    $currentKeyframe.sink { [weak self] frame in
      guard
        let self = self,
        let previewUntilFrame = self.previewUntilFrame else {
        return
      }
      if frame >= previewUntilFrame {
        self.isPlaying = false
        self.previewUntilFrame = nil
      }
    }.store(in: &cancellables)

    $document
      .compactMap {
        $0.mediaURL
      }
      .removeDuplicates()
      .sink { [videoPlayer] url in
        videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))
      }
      .store(in: &cancellables)
  }

  deinit {
    videoPlayer.unload()
  }

  func selectTracker(tracker: Tracker) {
    selectedTrackerIndex = document.trackers.firstIndex(of: tracker)
  }

  func changePositionKeyframeValue(tracker: Tracker, point: CGPoint) {
    guard let index = document.trackers.firstIndex(of: tracker) else {
      return
    }
    if selectedTrackerIndex != index {
      selectedTrackerIndex = index
    }
    document.trackers[index].position.keyframes[currentKeyframe] = point
  }

  func showExportDialog() {
    isPlaying = false
    showExportingOptionsDialog = true
  }

  func exportVideo() {
    isExportingVideo = true
    withAnimation {
      showExportingVideoModal = true
    }
    exportedAssetURL = nil
    videoExporter
      .export(document: document)
      .subscribe(on: DispatchQueue.global())
      .mapError {
        $0 as Error
      }
      .receive(on: RunLoop.main)
      .sink { [weak self] completion in
        self?.isExportingVideo = false
      } receiveValue: { [weak self] url in
        self?.showExportingVideoModal = false
        DispatchQueue.main.async {
          let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
      }.store(in: &cancellables)
  }

  func exportTemplate() {
    isExportingVideo = true
    withAnimation {
      showExportingVideoModal = true
    }
    documentService
      .save(document: document)
      .subscribe(on: DispatchQueue.global())
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        self?.isExportingVideo = false
        self?.showExportingVideoModal = false
      } receiveValue: { url in
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
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
    let tracker = Tracker(id: UUID(), text: "", position: animation)
    document.trackers.append(tracker)
    selectedTrackerIndex = document.trackers.count - 1
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
       document.trackers.count > index {
      document.trackers[index].position.keyframes.removeValue(forKey: currentKeyframe)
      goBack(frames: 1)
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
    if currentKeyframe == 0 {
      return
    }
    previewUntilFrame = currentKeyframe
    goBack(frames: currentKeyframe)
    isPlaying = true
  }

  func saveDocument() {
    documentService
      .save(document: document)
      .sink { _ in
      } receiveValue: { _ in
      }
      .store(in: &cancellables)
  }
}

extension VideoEditorViewModel {
  enum Action {
    case addTracker
    case deleteCurrentKeyframe
    case duplicateCurrentKeyframe
    case goForward(frames: Int)
    case removeSelectedTracker
    case play
    case pause
    case preview
    case editTracker
    case saveDocument
  }

  func submit(action: Action) {
    switch action {
    case .addTracker:
      addTracker()
    case .deleteCurrentKeyframe:
      deleteCurrentKeyframe()
    case .duplicateCurrentKeyframe:
      duplicateCurrentKeyframe()
    case .goForward(frames: let frames):
      goForward(frames: frames)
    case .removeSelectedTracker:
      removeSelectedTracker()
    case .play:
      previewUntilFrame = nil
      isPlaying = true
    case .pause:
      previewUntilFrame = nil
      isPlaying = false
    case .preview:
      preview()
    case .editTracker:
      if let _ = selectedTrackerIndex {
        isEditingText = true
      }
    case .saveDocument:
      saveDocument()
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
      return "Text added"
    case .deleteCurrentKeyframe:
      return "Keyframe deleted"
    case .duplicateCurrentKeyframe:
      return "Keyframe duplicated"
    case .goForward(frames: let frames):
      return "Jump forward \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
    case .removeSelectedTracker:
      return "Tracker deleted"
    case .play:
      return "Playing"
    case .pause:
      return "Paused"
    case .preview:
      return "Playing from the beginning"
    case .editTracker:
      return "Editing tracker"
    case .saveDocument:
      return "Saving document"
    }
  }
}
