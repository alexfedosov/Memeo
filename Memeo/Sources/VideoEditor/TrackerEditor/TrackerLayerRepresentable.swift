//
//  TrackerLayer.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import UIKit
import SwiftUI

protocol CALayerRepresentable {
  associatedtype CALayerType : CALayer
  func makeCALayer() -> Self.CALayerType
  func updateCALayer(_ layer: Self.CALayerType)
  static func dismantleCALayer(_ layer: Self.CALayerType)
}

class TrackerLayer: CALayer {
  let textLabel = UILabel()
  let touchAreaAround: CGFloat = 20
  
  override init() {
    super.init()
    masksToBounds = true

    textLabel.textColor = .white
    textLabel.textAlignment = .center
    textLabel.font = .boldSystemFont(ofSize: 14)
    
    addSublayer(textLabel.layer)
  }

  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func layoutSublayers() {
    super.layoutSublayers()
    textLabel.frame = bounds
  }

  func sizeToFit() {
    textLabel.sizeToFit()
    frame = CGRect(
      origin: CGPoint(
        x: frame.midX - textLabel.layer.frame.width / 2 - touchAreaAround,
        y: frame.midY - textLabel.layer.frame.height / 2 - touchAreaAround),
      size: CGSize(
        width: textLabel.bounds.width + touchAreaAround * 2,
        height: textLabel.bounds.height + touchAreaAround * 2))
  }
}

struct TrackerLayerRepresentable: CALayerRepresentable {
  var tracker: Tracker
  
  func makeCALayer() -> TrackerLayer {
    TrackerLayer()
  }
  
  func updateCALayer(_ layer: TrackerLayer) {
    layer.textLabel.text = tracker.uiText
    layer.sizeToFit()
  }
  
  static func dismantleCALayer(_ layer: TrackerLayer) {
    layer.textLabel.layer.removeFromSuperlayer()
  }
}
