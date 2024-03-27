//
//  TrackerEditorView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import AVKit
import SwiftUI

struct TrackerEditorView: UIViewRepresentable {
    let trackers: [Tracker]
    let numberOfKeyframes: Int
    let isPlaying: Bool
    let selectedTrackerIndex: Int?
    let duration: CFTimeInterval
    let playerItem: AVPlayerItem?

    var trackerTapped: ((Tracker) -> Void)? = nil
    var trackerPositionChanged: ((CGPoint, Tracker) -> Void)? = nil
    var trackerDoubleTapped: ((Tracker) -> Void)? = nil

    func makeUIView(context: Context) -> TrackersEditorUIView {
        let view = TrackersEditorUIView()
        view.playerItem = playerItem
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: TrackersEditorUIView, context: Context) {
        context.coordinator.trackerTapped = trackerTapped
        context.coordinator.trackerDoubleTapped = trackerDoubleTapped
        context.coordinator.trackerPositionChanged = trackerPositionChanged
        if uiView.playerItem != playerItem {
            uiView.playerItem = playerItem
        }
        uiView.updateTrackers(
            newTrackers: trackers, numberOfKeyframes: numberOfKeyframes, isPlaying: isPlaying, duration: duration,
            selectedTrackerIndex: selectedTrackerIndex)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: TrackersEditorUIViewDelegate {
        var trackerTapped: ((Tracker) -> Void)? = nil
        var trackerDoubleTapped: ((Tracker) -> Void)? = nil
        var trackerPositionChanged: ((CGPoint, Tracker) -> Void)? = nil

        func trackerPositionDidChange(position: CGPoint, tracker: Tracker) {
            trackerPositionChanged?(position, tracker)
        }

        func didTapOnTrackerLayer(tracker: Tracker) {
            trackerTapped?(tracker)
        }

        func didDoubleTapOnTrackerLayer(tracker: Tracker) {
            trackerDoubleTapped?(tracker)
        }
    }
}

struct TrackerEditorView_Previews: PreviewProvider {
    static var model = VideoEditorViewModel.preview
    static var previews: some View {
        TrackerEditorView(
            trackers: model.document.trackers,
            numberOfKeyframes: model.document.numberOfKeyframes,
            isPlaying: model.isPlaying,
            selectedTrackerIndex: 0,
            duration: model.document.duration,
            playerItem: nil
        )
        .background(Color.black)
    }
}

extension TrackerEditorView {
    func onTrackerDoubleTapped(_ callback: @escaping (Tracker) -> Void) -> Self {
        var copy = self
        copy.trackerDoubleTapped = callback
        return copy
    }

    func onTrackerTapped(_ callback: @escaping (Tracker) -> Void) -> Self {
        var copy = self
        copy.trackerTapped = callback
        return copy
    }

    func onTrackerPositionChanged(_ callback: @escaping (CGPoint, Tracker) -> Void) -> Self {
        var copy = self
        copy.trackerPositionChanged = callback
        return copy
    }
}
