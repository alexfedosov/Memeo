//
//  VideoEditorViewModel.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import AVFoundation
import Combine
import Foundation
import MobileCoreServices
import SwiftUI

@MainActor
class VideoEditorViewModel: ObservableObject {
    // MARK: - Logger
    private let logger = Logger.shared
    // MARK: - Services
    private let documentService: DocumentsService
    private let videoExporter: VideoExporter
    
    // MARK: - Published State
    @Published private(set) var document: Document
    @Published private(set) var currentKeyframe: Int = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isEditingText: Bool = false
    @Published private(set) var selectedTrackerIndex: Int?
    @Published private(set) var isExportingVideo = false
    @Published private(set) var isShowingInterstitialAd = false
    @Published private(set) var isShowingShareDialog = false
    @Published private(set) var lastActionDescription: String?
    @Published private(set) var exportedVideoUrl: URL?
    @Published private(set) var exportedGifUrl: URL?
    @Published private(set) var showHelp: Bool = false
    @Published private(set) var videoPlayer: VideoPlayer

    // MARK: - Private Properties
    private var lastActionDescriptionTimer: Timer?
    private let generator = UIImpactFeedbackGenerator()
    private var cancellables = Set<AnyCancellable>()
    private var delegateHandler: VideoPlayerDelegateHandler?
    
    @AppStorage("showHelpAtFirstLaunch") private var showHelpAtFirstLaunch = true

    // MARK: - Computed Properties
    var selectedTracker: Tracker? {
        if let index = selectedTrackerIndex, index < document.trackers.count {
            return document.trackers[index]
        } else {
            return nil
        }
    }

    var highlightedKeyframes: [Int: KeyframeType] {
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
    
    var canFadeInCurrentKeyframe: Bool {
        guard let selectedTracker = selectedTracker,
            let prevKey = selectedTracker.fade.keyframes.keys.sorted().last(where: { $0 <= currentKeyframe })
        else {
            return false
        }

        return !(selectedTracker.fade.keyframes[prevKey] ?? false)
    }

    // MARK: - Initialization
    init(document: Document, documentService: DocumentsService, videoExporter: VideoExporter) {
        self.document = document
        self.documentService = documentService
        self.videoExporter = videoExporter

        self.videoPlayer = VideoPlayer()
        
        logger.info("VideoEditorViewModel initialized for document: \(document.uuid)", category: .viewModel)
        
        if document.trackers.count > 0 {
            selectedTrackerIndex = 0
            logger.info("Selected first tracker for document: \(document.uuid), trackers count: \(document.trackers.count)", category: .viewModel)
        }
        
        // We need to set up a proper delegate that can handle the actor isolation
        // The following line sets up a custom delegate implementation
        // that will safely bridge the nonisolated protocol methods to our MainActor methods
        setupVideoPlayerDelegate()
        
        setupBindings()
        
        showHelp = showHelpAtFirstLaunch
        showHelpAtFirstLaunch = false
    }
    
    private func setupBindings() {
        // Handle play/pause state changes
        $isPlaying.removeDuplicates().sink { [weak self] isPlaying in
            guard let self = self else { return }
            if isPlaying {
                self.videoPlayer.play()
            } else {
                self.videoPlayer.pause()
            }
        }.store(in: &cancellables)

        // Handle keyframe changes when paused
        Publishers.CombineLatest($currentKeyframe.removeDuplicates(), $isPlaying)
            .filter { !$0.1 } // Only when not playing
            .map { $0.0 }
            .sink { [weak self] keyframe in
                guard let self = self else { return }
                self.videoPlayer.seek(to: keyframe, fps: self.document.fps)
            }.store(in: &cancellables)

        // Haptic feedback on keyframe changes when paused
        Publishers.CombineLatest($currentKeyframe.removeDuplicates(), $isPlaying)
            .filter { !$0.1 } // Only when not playing
            .sink { [weak self] _, _ in
                guard let self = self else { return }
                self.generator.impactOccurred(intensity: 0.5)
                self.generator.prepare()
            }.store(in: &cancellables)

        // Load media URL when document changes
        $document
            .compactMap { $0.mediaURL }
            .removeDuplicates()
            .map { url in AVAsset(url: url) }
            .flatMap { asset in
                Future<AVAsset, Never> { promise in
                    Task {
                        // Use the modern async API for loading
                        _ = try? await asset.load(.duration)
                        promise(.success(asset))
                    }
                }
            }
            .map { AVPlayerItem(asset: $0) }
            .sink { [weak self] playerItem in
                guard let self = self else { return }
                self.videoPlayer.replaceCurrentItem(with: playerItem)
            }
            .store(in: &cancellables)

        // Reset exported URLs when document changes
        $document
            .removeDuplicates()
            .map { _ in nil }
            .assign(to: &$exportedVideoUrl)

        $document
            .removeDuplicates()
            .map { _ in nil }
            .assign(to: &$exportedGifUrl)
    }

    deinit {
        Task { [weak self] in
            await self?.videoPlayer.unload()
        }
    }

    // MARK: - Public Methods
    func selectTracker(tracker: Tracker) {
        selectedTrackerIndex = document.trackers.firstIndex(of: tracker)
        logger.info("Selected tracker: \(tracker.id), index: \(selectedTrackerIndex ?? -1)", category: .viewModel)
    }

    func changePositionKeyframeValue(tracker: Tracker, point: CGPoint) {
        guard let index = document.trackers.firstIndex(of: tracker) else {
            logger.warning("Could not find tracker \(tracker.id) in document", category: .viewModel)
            return
        }
        if selectedTrackerIndex != index {
            selectedTrackerIndex = index
        }
        
        logger.info("Updating tracker \(tracker.id) position at keyframe \(currentKeyframe) to (\(point.x), \(point.y))", category: .viewModel)
        var updatedDocument = document
        updatedDocument.trackers[index].position.keyframes[currentKeyframe] = point
        document = updatedDocument
    }
    
    func updateTrackerText(text: String, style: TrackerStyle, size: TrackerSize) {
        guard let index = selectedTrackerIndex else { 
            logger.warning("No tracker selected for text update", category: .viewModel)
            return 
        }
        
        logger.info("Updating tracker text at index \(index): text='\(text)', style=\(style), size=\(size)", category: .viewModel)
        var updatedDocument = document
        updatedDocument.trackers[index].text = text
        updatedDocument.trackers[index].style = style
        updatedDocument.trackers[index].size = size
        document = updatedDocument
        
        setIsEditingText(false)
    }
    
    func setIsEditingText(_ isEditing: Bool) {
        isEditingText = isEditing
    }
    
    func setIsPlaying(_ playing: Bool) {
        if playing && currentKeyframe == document.numberOfKeyframes - 1 {
            logger.info("Restarting playback from beginning", category: .viewModel)
            currentKeyframe = 0
        }
        logger.info("Set playing state: \(playing)", category: .viewModel)
        isPlaying = playing
    }
    
    func goToNextKeyframe() {
        setIsPlaying(false)
        currentKeyframe = min(document.numberOfKeyframes - 1, currentKeyframe + 1)
    }
    
    func goToPreviousKeyframe() {
        setIsPlaying(false)
        currentKeyframe = max(0, currentKeyframe - 1)
    }
    
    func goForward(frames: Int) {
        setIsPlaying(false)
        currentKeyframe = min(document.numberOfKeyframes - 1, currentKeyframe + frames)
    }
    
    func goBack(frames: Int) {
        setIsPlaying(false)
        currentKeyframe = max(0, currentKeyframe - frames)
    }
    
    func setShowHelp(_ show: Bool) {
        showHelp = show
    }

    func share() async throws {
        logger.info("Starting share process for document: \(document.uuid)", category: .export)
        setIsPlaying(false)
        
        withAnimation {
            isExportingVideo = true
        }
        
        defer {
            withAnimation {
                isExportingVideo = false
            }
        }
        
        let (videoUrl, gifUrl) = try await exportVideoSignal()
        exportedVideoUrl = videoUrl
        exportedGifUrl = gifUrl
        
        logger.info("Successfully exported video for sharing", category: .export)
        withAnimation {
            isShowingShareDialog = true
        }
    }
    
    func closeShareDialog() {
        isShowingShareDialog = false
    }

    func cleanDocumentsDirectory() {
        Task {
            await documentService.cleanDocumentsDirectoryAsync()
        }
    }
    
    // MARK: - Action Handler
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
        case .goForward(let frames):
            goForward(frames: frames)
        case .goBack(let frames):
            goBack(frames: frames)
        case .removeSelectedTracker:
            removeSelectedTracker()
        case .play:
            setIsPlaying(true)
        case .pause:
            setIsPlaying(false)
        case .editTracker:
            if selectedTrackerIndex != nil {
                setIsEditingText(true)
            }
        case .fadeInTracker: 
            fadeInCurrentKeyframe()
        case .fadeOutTracker: 
            fadeOutCurrentKeyframe()
        }

        showLastActionDescription(text: action.toastText())
    }

    // MARK: - Private Methods
    private func exportVideoSignal() async throws -> (URL, URL?) {
        if let videoUrl = exportedVideoUrl {
            return (videoUrl, exportedGifUrl)
        }

        let url = try await videoExporter.export(document: document)
        let gifUrl = document.duration < 10 ? videoExporter.exportGif(url: url, trim: false) : nil
        return (url, gifUrl)
    }
    
    private func addTracker() {
        let animation = Animation<CGPoint>(
            id: UUID(),
            keyframes: [currentKeyframe: CGPoint(x: 0.5, y: 0.5)],
            key: "position")

        var opacity = Animation<Bool>(
            id: UUID(),
            keyframes: [:],
            key: "opacity")

        let rotation = Animation<Double>(
            id: UUID(),
            keyframes: [:],
            key: "rotation"
        )

        if currentKeyframe > 0 {
            opacity.keyframes[0] = false
            opacity.keyframes[currentKeyframe] = true
        }
        
        let tracker = Tracker(
            id: UUID(), 
            text: "", 
            style: .transparent, 
            size: .small, 
            position: animation, 
            fade: opacity, 
            rotation: rotation
        )
        
        var updatedDocument = document
        updatedDocument.trackers.append(tracker)
        document = updatedDocument
        
        selectedTrackerIndex = document.trackers.count - 1
    }

    private func removeSelectedTracker() {
        guard let index = selectedTrackerIndex, document.trackers.count > index else { return }
        
        selectedTrackerIndex = nil
        
        var updatedDocument = document
        updatedDocument.trackers.remove(at: index)
        document = updatedDocument
    }

    private func deleteCurrentKeyframe() {
        guard let index = selectedTrackerIndex, document.trackers.count > index else { return }
        
        var updatedDocument = document
        updatedDocument.trackers[index].position.keyframes.removeValue(forKey: currentKeyframe)
        updatedDocument.trackers[index].fade.keyframes.removeValue(forKey: currentKeyframe)
        document = updatedDocument
        
        goBack(frames: 1)
    }

    private func duplicateCurrentKeyframe() {
        guard let index = selectedTrackerIndex,
              document.trackers.count > index,
              currentKeyframe < document.numberOfKeyframes,
              let value = document.trackers[index].position.keyframes[currentKeyframe] else { return }
        
        var updatedDocument = document
        updatedDocument.trackers[index].position.keyframes[currentKeyframe + 1] = value
        document = updatedDocument
        
        currentKeyframe += 1
    }

    private func fadeInCurrentKeyframe() {
        guard let index = selectedTrackerIndex else { return }
        
        var updatedDocument = document
        updatedDocument.trackers[index].fade.keyframes[currentKeyframe] = true
        document = updatedDocument
    }

    private func fadeOutCurrentKeyframe() {
        guard let index = selectedTrackerIndex else { return }
        
        var updatedDocument = document
        updatedDocument.trackers[index].fade.keyframes[currentKeyframe] = false
        document = updatedDocument
    }

    private func showLastActionDescription(text: String) {
        lastActionDescription = text
        lastActionDescriptionTimer?.invalidate()
        
        // Use a non-capturing approach to avoid Main actor violation in Swift 6
        let timer = Timer.scheduledTimer(
            withTimeInterval: 2, repeats: false,
            block: { [weak self] _ in
                // Explicitly dispatch to MainActor to modify the property
                Task { @MainActor in
                    guard let self = self else { return }
                    self.lastActionDescription = nil
                }
            })
        
        lastActionDescriptionTimer = timer
    }
}

// MARK: - Preview Helper
extension VideoEditorViewModel {
    static var preview: VideoEditorViewModel {
        let documentsService = DocumentsService()
        let videoExporter = VideoExporter()
        return VideoEditorViewModel(
            document: Document.loadPreviewDocument(),
            documentService: documentsService,
            videoExporter: videoExporter
        )
    }
}

// MARK: - Media Player Delegate Handling
extension VideoEditorViewModel {
    private func setupVideoPlayerDelegate() {
        // Create a separate class that conforms to MediaPlayerDelegate
        // This is needed because protocols don't respect actor isolation in Swift 6
        let delegateHandler = VideoPlayerDelegateHandler(viewModel: self)
        
        // Create a property to store the delegate to prevent it from being deallocated
        // This is a common pattern for delegates in Swift
        self.delegateHandler = delegateHandler
        
        // Set the delegate on the player
        videoPlayer.delegate = delegateHandler
    }
    
    // This method is called by our delegate handler on the main actor
    @MainActor
    fileprivate func handlePlayerDidPlayToTime(time: CMTime, duration: CMTime) {
        guard time.isNumeric && time.isValid else { return }
        
        let notRoundedFrameIndex = Double(time.value) / (Double(time.timescale) / Double(self.document.fps))
        if notRoundedFrameIndex.isFinite {
            self.currentKeyframe = min(
                Int(notRoundedFrameIndex.rounded(.toNearestOrAwayFromZero)), 
                self.document.numberOfKeyframes - 1
            )
        }
    }
    
    // This method is called by our delegate handler on the main actor
    @MainActor
    fileprivate func handlePlayerDidPlayToEnd() {
        self.isPlaying = false
    }
}

// Separate class to handle delegate methods without actor isolation issues
// This acts as a bridge between the nonisolated protocol and our MainActor methods
final class VideoPlayerDelegateHandler: NSObject, MediaPlayerDelegate {
    // We need to use a noncapturing property to store the weak reference 
    // to avoid MainActor isolation issues
    private weak var viewModel: VideoEditorViewModel?
    
    // Since the init is called from a MainActor context, we need to make it MainActor to access the viewModel
    @MainActor
    init(viewModel: VideoEditorViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    // These methods are called from non-isolated contexts
    func mediaPlayerDidPlayToTime(time: CMTime, duration: CMTime) {
        // Explicitly dispatch to MainActor
        Task { @MainActor in
            viewModel?.handlePlayerDidPlayToTime(time: time, duration: duration)
        }
    }
    
    func mediaPlayerDidPlayToEnd() {
        // Explicitly dispatch to MainActor
        Task { @MainActor in
            viewModel?.handlePlayerDidPlayToEnd()
        }
    }
}

// MARK: - Help Protocol
protocol Help {
    func toastText() -> String
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
        case .goForward(let frames):
            return "Jump forward \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
        case .goBack(let frames):
            return "Jump back \(frames) \(frames == 1 ? "keyframe" : "keyframes")"
        case .removeSelectedTracker:
            return "Tracker deleted"
        case .play:
            return "Playing"
        case .pause:
            return "Paused"
        case .editTracker:
            return "Editing tracker"
        case .fadeInTracker:
            return String(localized: "Show text")
        case .fadeOutTracker:
            return String(localized: "Hide text")
        }
    }
}

// MARK: - Publisher Extensions
extension Future where Failure == Error {
    convenience init(operation: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
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
