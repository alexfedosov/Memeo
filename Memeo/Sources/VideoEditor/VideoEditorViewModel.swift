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
import MobileCoreServices

class VideoEditorViewModel: ObservableObject {
  let documentService = DocumentsService()

  @Published var document: Document

  @Published var currentKeyframe: Int = 0
  @Published var isPlaying: Bool = false
  @Published var isEditingText: Bool = false
  @Published var selectedTrackerIndex: Int?

  @Published var isExportingVideo = false
  @Published var isShowingInterstitialAd = false
  @Published var isShowingShareDialog = false

  @Published var lastActionDescription: String?
  var lastActionDescriptionTimer: Timer?

  var videoPlayer: VideoPlayer
  var videoExporter = VideoExporter()
  let generator = UIImpactFeedbackGenerator()

  @Published var exportedVideoUrl: URL?
  @Published var exportedGifUrl: URL?

  var cancellables = Set<AnyCancellable>()

  var selectedTracker: Tracker? {
    get {
      if let index = selectedTrackerIndex, index < document.trackers.count {
        return document.trackers[index]
      } else {
        return nil
      }
    }
  }

  var highlightedKeyframes: [Int: KeyframeType] {
    get {
      guard let selectedTracker = selectedTracker else {
        return [:]
      }
      var keyframes = [Int: KeyframeType]()

      for key in selectedTracker.position.keyframes.keys {
        keyframes[key] = .position
      }

      for (key, value) in selectedTracker.fade.keyframes {
        keyframes[key] = value == true ? .fadeIn : .fadeOut
      }

      return keyframes
    }
  }
  var canFadeInCurrentKeyframe: Bool {
    guard let selectedTracker = selectedTracker,
          let prevKey = selectedTracker.fade.keyframes.keys.sorted().last(where: { $0 <= currentKeyframe })
      else {
      return false
    }

    return !(selectedTracker.fade.keyframes[prevKey] ?? false)
  }

  init(document: Document) {
    self.document = document

    if document.trackers.count > 0 {
      selectedTrackerIndex = 0
    }

    videoPlayer = VideoPlayer()
    videoPlayer.delegate = self

    $isPlaying.removeDuplicates().sink { [videoPlayer] isPlaying in
      if isPlaying {
        videoPlayer.play()
      } else {
        videoPlayer.pause()
      }
    }.store(in: &cancellables)

    Publishers.CombineLatest($currentKeyframe.removeDuplicates(), $isPlaying)
      .filter {
        !$0.1
      }
      .map {
        $0.0
      }
      .sink { [videoPlayer] keyframe in
        videoPlayer.seek(to: keyframe, fps: document.fps)
      }.store(in: &cancellables)

    Publishers.CombineLatest($currentKeyframe.removeDuplicates(), $isPlaying)
      .filter {
        !$0.1
      }
      .sink { [generator] _, _ in
        generator.impactOccurred(intensity: 0.5)
        generator.prepare()
      }.store(in: &cancellables)

    $document
      .compactMap {
        $0.mediaURL
      }
      .removeDuplicates()
      .map { url in
        AVAsset(url: url)
      }
      .flatMap { asset in
        Future<AVAsset, Never> { promise in
          asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            promise(.success(asset))
          }
        }
      }
      .map {
        AVPlayerItem(asset: $0)
      }
      .sink { [videoPlayer] playerItem in
        videoPlayer.replaceCurrentItem(with: playerItem)
      }
      .store(in: &cancellables)

    $document
      .removeDuplicates()
      .map { _ in
        nil
      }
      .print("exportedVideoUrl set to nil")
      .assign(to: &$exportedVideoUrl)

    $document
      .removeDuplicates()
      .map { _ in
        nil
      }
      .assign(to: &$exportedGifUrl)
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

  func share() {
    isPlaying = false
    Publishers
      .Zip(showAds(count: 2)
        .mapError {
          $0 as Error
        },
        exportVideoSignal().mapError {
          $0 as Error
        })
      .receive(on: RunLoop.main)
      .delay(for: .seconds(1), scheduler: RunLoop.main)
      .sink(receiveCompletion: { [weak self] completion in
        guard let self = self else {
          return
        }
        withAnimation {
          self.isExportingVideo = false
        }

        switch completion {
        case .finished:
          withAnimation {
            self.isShowingShareDialog = true
          }
        case .failure(let error):
          print(error)
        }
      },
        receiveValue: { [weak self] value in
          let urls = value.1
          self?.exportedVideoUrl = urls.0
          self?.exportedGifUrl = urls.1
        })
      .store(in: &cancellables)
  }

  func showAds(count: Int) -> AnyPublisher<(), Never> {
    guard InterstitialAd.shared.interstitialAd != nil else {
      return Just(()).eraseToAnyPublisher()
    }

    let publisher = $isShowingInterstitialAd
      .side { [weak self] _ in
        self?.isExportingVideo = true
      }
      .removeDuplicates()
      .dropFirst()
      .filter {
        !$0
      }
      .delay(for: .seconds(2), scheduler: RunLoop.main)
      .side { [weak self] _ in
        self?.isShowingInterstitialAd = true
      }
      .collect(count - 1)
      .first()
      .map { _ in
        ()
      }
      .eraseToAnyPublisher()

    isShowingInterstitialAd = true
    return publisher
  }

  func exportVideoSignal() -> AnyPublisher<(URL, URL?), VideoExporterError> {
    if let videoUrl = exportedVideoUrl {
      return Just((videoUrl, exportedGifUrl)).setFailureType(to: VideoExporterError.self).eraseToAnyPublisher()
    }

    return Just(())
      .side { [weak self] in
        withAnimation {
          self?.isExportingVideo = true
        }
      }
      .receive(on: DispatchQueue.global())
      .compactMap { [weak self] _ in
        guard let self = self else {
          return nil
        }
        return (self.videoExporter, self.document)
      }
      .flatMap { (exporter: VideoExporter, document: Document) in
        exporter.export(document: document)
          .receive(on: DispatchQueue.global())
          .map { url in
            (url, document.duration < 10 ? exporter.exportGif(url: url, trim: false) : nil)
          }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }

//  func exportTemplate() {
//    self?.sharingStep = .shareDialog
//    withAnimation {
//      showExportingVideoModal = true
//    }
//    documentService
//      .save(document: document)
//      .subscribe(on: DispatchQueue.global())
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] completion in
//        self?.isExportingVideo = false
//        self?.showExportingVideoModal = false
//      } receiveValue: { url in
//        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
//      }.store(in: &cancellables)
//  }
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

    var opacity = Animation<Bool>(id: UUID(),
      keyframes: [:],
      key: "opacity")

    if currentKeyframe > 0 {
      opacity.keyframes[0] = false
      opacity.keyframes[currentKeyframe] = true
    }
    let tracker = Tracker(id: UUID(), text: "", position: animation, fade: opacity)
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
      document.trackers[index].fade.keyframes.removeValue(forKey: currentKeyframe)
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

  func saveDocument() {
    documentService
      .save(document: document)
      .sink { _ in
      } receiveValue: { _ in
      }
      .store(in: &cancellables)
  }

  private func fadeInCurrentKeyframe() {
    guard let index = selectedTrackerIndex else {
      return
    }
    document.trackers[index].fade.keyframes[currentKeyframe] = true
  }

  private func fadeOutCurrentKeyframe() {
    guard let index = selectedTrackerIndex else {
      return
    }
    document.trackers[index].fade.keyframes[currentKeyframe] = false
  }
}

extension VideoEditorViewModel {
  enum Action {
    case addTracker
    case deleteCurrentKeyframe
    case duplicateCurrentKeyframe
    case goForward(frames: Int)
    case goBack(frames: Int)
    case removeSelectedTracker
    case play
    case pause
    case editTracker
    case saveDocument
    case fadeInTracker
    case fadeOutTracker
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
    case .goBack(frames: let frames):
      goBack(frames: frames)
    case .removeSelectedTracker:
      removeSelectedTracker()
    case .play:
      if currentKeyframe == document.numberOfKeyframes - 1 {
        currentKeyframe = 0
      }
      isPlaying = true
    case .pause:
      isPlaying = false
    case .editTracker:
      if let _ = selectedTrackerIndex {
        isEditingText = true
      }
    case .saveDocument:
      saveDocument()
    case .fadeInTracker: fadeInCurrentKeyframe()
    case .fadeOutTracker: fadeOutCurrentKeyframe()
    }

    showLastActionDescription(text: action.toastText())
  }

  func showLastActionDescription(text: String) {
    lastActionDescription = text
    lastActionDescriptionTimer?.invalidate()
    lastActionDescriptionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [weak self] _ in
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
    case .goBack(frames: let frames):
      return "Jump back \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
    case .removeSelectedTracker:
      return "Tracker deleted"
    case .play:
      return "Playing"
    case .pause:
      return "Paused"
    case .editTracker:
      return "Editing tracker"
    case .saveDocument:
      return "Saving document"
    case .fadeInTracker:
      return "Show text"
    case .fadeOutTracker:
      return "Hide text"
    }
  }
}

extension Publisher {
  public func side(_ closure: @escaping (Self.Output) -> Void) -> AnyPublisher<Self.Output, Self.Failure> {
    self.map { input in
      closure(input)
      return input
    }.eraseToAnyPublisher()
  }
}
