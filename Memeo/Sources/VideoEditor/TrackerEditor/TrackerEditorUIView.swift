//
//  TrackerEditorUIView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import UIKit
import SwiftUI

class TrackersEditorUIView: UIView {
  weak var delegate: TrackersEditorUIViewDelegate?
  
  var trackerLayers: [TrackerLayerRepresentable] = []
  var trackerCALayers: [TrackerLayer] {
    get {
      layer.sublayers?.compactMap { $0 as? TrackerLayer } ?? []
    }
  }

  var movingTracker: TrackerLayer?

  var lastLocation: CGPoint = .zero
  var touchLocationInMovingTracker: CGPoint = .zero

  let panGestureRecognizer = UIPanGestureRecognizer()
  let tapGestureRecognizer = UITapGestureRecognizer()

  var currentKeyframe: Int = 0
  var numberOfKeyframes: Int = 0
  var isPlaying: Bool = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configureView()
  }
  
  func configureView() {
    panGestureRecognizer.minimumNumberOfTouches = 1
    panGestureRecognizer.maximumNumberOfTouches = 1
    panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
    addGestureRecognizer(panGestureRecognizer)

    tapGestureRecognizer.addTarget(self, action: #selector(handleTap))
    addGestureRecognizer(tapGestureRecognizer)

    layer.masksToBounds = true
  }
  
  func getTracker(at location: CGPoint) -> TrackerLayer? {
    var possiblyTracker = layer.presentation()?.hitTest(location)
    while !(possiblyTracker is TrackerLayer) && possiblyTracker?.superlayer != nil {
      possiblyTracker = possiblyTracker?.superlayer
    }
    return possiblyTracker as? TrackerLayer
  }
  
  func getTrackerModel(for caViewLayer: TrackerLayer) -> TrackerLayerRepresentable? {
    guard let index = trackerCALayers.firstIndex(where: { $0 === caViewLayer }) else {
      return nil
    }
    return trackerLayers[index]
  }
  
  @objc func handlePanGesture(sender: UIPanGestureRecognizer) {
    let location = sender.location(in: self)
    switch sender.state {
    case .began:
      guard let trackerPresentation = getTracker(at: location) else { break }
      let tracker = trackerPresentation.model()
      tracker.position = trackerPresentation.position
      tracker.removeAllAnimations()

      movingTracker = tracker
      touchLocationInMovingTracker = tracker.convert(location, from: layer) - CGPoint(x: tracker.bounds.width / 2, y: tracker.bounds.height / 2)
    case .changed:
      guard let movingTracker = movingTracker else {
        break
      }
      CATransaction.setDisableActions(true)
      movingTracker.position = location - touchLocationInMovingTracker
      if let tracker = getTrackerModel(for: movingTracker) {
        delegate?.trackerPositionDidChange(position: movingTracker.position, tracker: tracker.tracker)
      }
    case .cancelled: fallthrough
    case .ended: fallthrough
    case .failed:
      movingTracker = nil
      touchLocationInMovingTracker = .zero
    default: break
    }
  }

  @objc func handleTap(sender: UITapGestureRecognizer) {
    let location = sender.location(in: self)
    guard let trackerPresentation = getTracker(at: location) else { return }

    let tracker = trackerPresentation.model()
    if let model = getTrackerModel(for: tracker) {
      delegate?.didTapOnTrackerLayer(tracker: model.tracker)
    }
  }

  
  func updateTrackers(modelTrackers: [Tracker],
                      numberOfKeyframes: Int,
                      currentKeyframe: Int,
                      isPlaying: Bool) {
    let oldTrackers = trackerLayers.map { $0.tracker }
    let diff = modelTrackers.difference(from: oldTrackers, by: { $0.id == $1.id })
    for change in diff {
      switch change {
      case .insert(offset: let offset, element: let element, associatedWith: _):
        let trackerLayer = TrackerLayerRepresentable(tracker: element)
        trackerLayers.insert(trackerLayer, at: offset)
        let createdTrackerLayer = trackerLayer.makeCALayer()
        trackerLayer.updateCALayer(createdTrackerLayer)
        layer.insertSublayer(createdTrackerLayer, at: UInt32(offset))
        let animation = element.position.makeCAAnimation(numberOfKeyframes: numberOfKeyframes,
                                                         currentKeyframe: currentKeyframe,
                                                         duration: 5,
                                                         speed: isPlaying ? 1 : 0)
        layer.add(animation, forKey: animation.keyPath)
      case .remove(offset: let offset, element: _, associatedWith: _):
        guard let layer = layer.sublayers?[offset] as? TrackerLayer else {
          break
        }
        TrackerLayerRepresentable.dismantleCALayer(layer)
        layer.removeFromSuperlayer()
        trackerLayers.remove(at: offset)
      }
    }
    
    let needUpdate = self.isPlaying != isPlaying
      || self.currentKeyframe != currentKeyframe
      || self.numberOfKeyframes != numberOfKeyframes
    
    for (index, newTracker) in modelTrackers.enumerated() {
      if newTracker != trackerLayers[index].tracker || needUpdate {
        guard let layer = layer.sublayers?[index] as? TrackerLayer else {
          continue
        }
        trackerLayers[index].tracker = newTracker
        trackerLayers[index].updateCALayer(layer)
        let animation = newTracker.position.makeCAAnimation(numberOfKeyframes: numberOfKeyframes,
                                                            currentKeyframe: currentKeyframe,
                                                            duration: 12,
                                                            speed: isPlaying ? 1 : 0)
        layer.add(animation, forKey: animation.keyPath)
      }
    }
  }
}

protocol TrackersEditorUIViewDelegate: AnyObject {
  func trackerPositionDidChange(position: CGPoint, tracker: Tracker)
  func didTapOnTrackerLayer(tracker: Tracker)
}
