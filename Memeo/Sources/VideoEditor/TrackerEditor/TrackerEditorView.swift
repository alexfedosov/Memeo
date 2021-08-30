//
//  TrackerEditorView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI

struct TrackerEditorView: UIViewRepresentable {
  let trackers: [Tracker]
  let numberOfKeyframes: Int
  let currentKeyframe: Int
  let isPlaying: Bool
  let duration: CFTimeInterval
  var trackerTapped: ((Tracker) -> Void)? = nil
  var trackerPositionChanged: ((CGPoint, Tracker) -> Void)? = nil
  
  func makeUIView(context: Context) -> TrackersEditorUIView {
    let view = TrackersEditorUIView()
    view.delegate = context.coordinator
    return view
  }
  
  func updateUIView(_ uiView: TrackersEditorUIView, context: Context) {
    context.coordinator.trackerTapped = trackerTapped
    context.coordinator.trackerPositionChanged = trackerPositionChanged
    uiView.updateTrackers(newTrackers: trackers,
                          numberOfKeyframes: numberOfKeyframes,
                          currentKeyframe: currentKeyframe,
                          isPlaying: isPlaying,
                          duration: duration)
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  class Coordinator: TrackersEditorUIViewDelegate {
    var trackerTapped: ((Tracker) -> Void)? = nil
    var trackerPositionChanged: ((CGPoint, Tracker) -> Void)? = nil
    
    func trackerPositionDidChange(position: CGPoint, tracker: Tracker) {
      trackerPositionChanged?(position, tracker)
    }
    
    func didTapOnTrackerLayer(tracker: Tracker) {
      trackerTapped?(tracker)
    }
  }
}

struct TrackerEditorView_Previews: PreviewProvider {
  static var model = VideoEditorViewModel.preview
  static var previews: some View {
    TrackerEditorView(trackers: model.document.trackers,
                      numberOfKeyframes: model.document.numberOfKeyframes,
                      currentKeyframe: model.currentKeyframe,
                      isPlaying: model.isPlaying,
                      duration: model.document.duration)
      .background(Color.black)
  }
}

extension TrackerEditorView {
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
