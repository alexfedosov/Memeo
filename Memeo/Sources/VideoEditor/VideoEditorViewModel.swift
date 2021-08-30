//
//  VideoEditorViewModel.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import SwiftUI

class VideoEditorViewModel: ObservableObject {
  @Published var document: Document
  @Published var currentKeyframe: Int = 0
  @Published var isPlaying: Bool = false
  @Published var isEditingText: Bool = false
  @Published var selectedTrackerIndex: Int?
  
  init(document: Document) {
    self.document = document
    if document.trackers.count > 0 {
      selectedTrackerIndex = 0
    }
  }
  
  func addTracker() {
    let animation = Animation<Point>(id: UUID(), keyframes: [:], key: "position")
    let tracker = Tracker(id: UUID(), text: "Tracker \(document.trackers.count + 1)", position: animation)
    document.trackers.append(tracker)
  }
  
  func removeTracker() {
    if let index = selectedTrackerIndex,
       document.trackers.count > index {
      selectedTrackerIndex = nil
      document.trackers.remove(at: index)
    }
  }
  
  func swapFirstAndLastTrackers() {
    document.trackers.swapAt(0, document.trackers.count - 1)
  }
  
  func updateText() {
    document.trackers[0].text = String(document.trackers[0].text.reversed())
  }
  
  func selectTracker(tracker: Tracker) {
    selectedTrackerIndex = document.trackers.firstIndex(of: tracker)
  }
  
  func changePositionKeyframeValue(tracker: Tracker, point: CGPoint) {
    guard let index = document.trackers.firstIndex(of: tracker) else { return }
    if selectedTrackerIndex != index {
      selectedTrackerIndex = index
    }
    document.trackers[index].position.keyframes[currentKeyframe] = Point(x: Float(point.x), y: Float(point.y))
  }
}
