//
//  TrackerEditorUIView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import UIKit
import SwiftUI
import AVKit

class TrackersEditorUIView: UIView {
  weak var delegate: TrackersEditorUIViewDelegate?

  var trackerLayers: [TrackerLayerRepresentable] = []
  var trackerCALayers: [TrackerLayer] {
    get {
      layer.sublayers?.compactMap {
        $0 as? TrackerLayer
      } ?? []
    }
  }

  var movingTracker: TrackerLayer?

  var lastLocation: CGPoint = .zero
  var touchLocationInMovingTracker: CGPoint = .zero

  let panGestureRecognizer = UIPanGestureRecognizer()
  let doubleTapGestureRecognizer = UITapGestureRecognizer()
  let tapGestureRecognizer = UITapGestureRecognizer()

  var numberOfKeyframes: Int = 0
  var duration: Double = 0
  var isPlaying: Bool = false
  var selectedTrackerIndex: Int? = nil

  override static var layerClass: AnyClass {
    AVSynchronizedLayer.self
  }

  var playerItem: AVPlayerItem? {
    get {
      (layer as! AVSynchronizedLayer).playerItem
    }
    set {
      (layer as! AVSynchronizedLayer).playerItem = newValue
    }
  }

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

    doubleTapGestureRecognizer.addTarget(self, action: #selector(handleDoubleTap))
    doubleTapGestureRecognizer.numberOfTapsRequired = 2
    addGestureRecognizer(doubleTapGestureRecognizer)

    tapGestureRecognizer.addTarget(self, action: #selector(handleTap))
    tapGestureRecognizer.numberOfTapsRequired = 1
    addGestureRecognizer(tapGestureRecognizer)

    layer.masksToBounds = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    forceUpdateTrackers()
  }

  func forceUpdateTrackers() {
    updateTrackers(newTrackers: trackerLayers.map {
      $0.tracker
    }, numberOfKeyframes: numberOfKeyframes, isPlaying: isPlaying, duration: duration, selectedTrackerIndex: selectedTrackerIndex, forceUpdate: true)
  }

  func getTracker(at location: CGPoint) -> TrackerLayer? {
    var possiblyTracker = layer.presentation()?.hitTest(location)
    while !(possiblyTracker is TrackerLayer) && possiblyTracker?.superlayer != nil {
      possiblyTracker = possiblyTracker?.superlayer
    }

    if let tracker = possiblyTracker as? TrackerLayer {
      return tracker
    } else if let selectedTrackerIndex = selectedTrackerIndex {
      return trackerCALayers[selectedTrackerIndex].presentation()
    }
    return nil
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
      guard let trackerPresentation = getTracker(at: location) else {
        break
      }
      let tracker = trackerPresentation.model()
      tracker.position = trackerPresentation.position
      tracker.opacity = trackerPresentation.opacity
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
        let position = CGPoint(x: movingTracker.position.x / bounds.size.width,
          y: movingTracker.position.y / bounds.size.height)
        delegate?.trackerPositionDidChange(position: position, tracker: tracker.tracker)
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
    guard let trackerPresentation = getTracker(at: location) else {
      return
    }

    let tracker = trackerPresentation.model()
    if let model = getTrackerModel(for: tracker) {
      delegate?.didTapOnTrackerLayer(tracker: model.tracker)
    }
  }

  @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
    let location = sender.location(in: self)
    guard let trackerPresentation = getTracker(at: location) else {
      return
    }

    let tracker = trackerPresentation.model()
    if let model = getTrackerModel(for: tracker) {
      delegate?.didDoubleTapOnTrackerLayer(tracker: model.tracker)
    }
  }

  func updateTrackers(newTrackers: [Tracker], numberOfKeyframes: Int, isPlaying: Bool, duration: CFTimeInterval, selectedTrackerIndex: Int?, forceUpdate: Bool = false) {
    let oldTrackers = trackerLayers.map {
      $0.tracker
    }
    let diff = newTrackers.difference(from: oldTrackers, by: { $0.id == $1.id })
    for change in diff {
      switch change {
      case .insert(offset: let offset, element: let element, associatedWith: _):
        let trackerLayer = TrackerLayerRepresentable(tracker: element, isSelected: offset == selectedTrackerIndex)
        trackerLayers.insert(trackerLayer, at: offset)
        layer.insertSublayer(trackerLayer.makeCALayer(), at: UInt32(offset))
      case .remove(offset: let offset, element: _, associatedWith: _):
        guard let trackerLayer = layer.sublayers?[offset] as? TrackerLayer else {
          break
        }
        TrackerLayerRepresentable.dismantleCALayer(trackerLayer)
        trackerLayer.removeFromSuperlayer()
        trackerLayers.remove(at: offset)
      }
    }

    let needUpdate = self.isPlaying != isPlaying
      || self.selectedTrackerIndex != selectedTrackerIndex
      || forceUpdate
      || diff.insertions.count > 0

    self.isPlaying = isPlaying
    self.numberOfKeyframes = numberOfKeyframes
    self.duration = duration
    self.selectedTrackerIndex = selectedTrackerIndex

    if bounds.size == .zero {
      return
    }

    for (index, newTracker) in newTrackers.enumerated() {
      let trackerChanged = newTracker != trackerLayers[index].tracker
      guard trackerChanged || needUpdate, let layer = layer.sublayers?[index] as? TrackerLayer else {
        continue
      }
      if newTracker.position != trackerLayers[index].tracker.position || needUpdate {
        let positionAnimation = newTracker.position.makeCAAnimation(numberOfKeyframes: numberOfKeyframes, duration: duration, frameSize: bounds.size)
        layer.removeAllAnimations()
        layer.add(positionAnimation, forKey: positionAnimation.keyPath)
      }

      if newTracker.fade != trackerLayers[index].tracker.fade || needUpdate {
        let opacityAnimation = newTracker.fade.makeCAAnimation(numberOfKeyframes: numberOfKeyframes, duration: duration, isPlaying: isPlaying)
        opacityAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        layer.textLabel.layer.removeAllAnimations()
        layer.textLabel.layer.add(opacityAnimation, forKey: opacityAnimation.keyPath)
      }

      trackerLayers[index].isSelected = !isPlaying && selectedTrackerIndex == index
      trackerLayers[index].tracker = newTracker
      trackerLayers[index].updateCALayer(layer)
    }
  }
}

protocol TrackersEditorUIViewDelegate: AnyObject {
  func trackerPositionDidChange(position: CGPoint, tracker: Tracker)
  func didTapOnTrackerLayer(tracker: Tracker)
  func didDoubleTapOnTrackerLayer(tracker: Tracker)
}
