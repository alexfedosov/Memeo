//
//  TimelineView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import UIKit
import SwiftUI

struct TimelineViewDrawConfig {
  let size: CGSize
  let spacing: CGFloat
}

class TimelineView: UIView {
  var highlightedKeyframes = [Int: KeyframeType]()
  let drawingConfig: TimelineViewDrawConfig
  let fillColor = UIColor(red: 46.0 / 255.0, green: 46.0 / 255.0, blue: 46.0 / 255.0, alpha: 0.6)
  var offset: CGFloat = 0
  
  init(drawingConfig: TimelineViewDrawConfig) {
    self.drawingConfig = drawingConfig
    super.init(frame: .zero)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    guard let contextRef = UIGraphicsGetCurrentContext() else {
      return
    }
    if isOpaque {
      contextRef.clear(rect)
    }
    
    let y = (bounds.height - drawingConfig.size.height) / 2
    let width = drawingConfig.size.width + drawingConfig.spacing
    let drawFrom = Int(floor(rect.minX / width))
    let drawTo = Int(ceil(rect.maxX / width))
    for i in drawFrom..<drawTo {
      contextRef.setFillColor(fillColor.cgColor)
      let markerRect = CGRect(
        origin: CGPoint(x: CGFloat(i) * width, y: y),
        size: drawingConfig.size
      )
      let markerPath = CGPath(roundedRect: markerRect,
                              cornerWidth: 6.5,
                              cornerHeight: 6.5,
                              transform: nil)
      contextRef.addPath(markerPath)
      contextRef.fillPath()
      
      if let keyframe = highlightedKeyframes[i] {
        let diameter = min(drawingConfig.size.width, drawingConfig.size.height)
        let keyframeMarkerRect = CGRect(
          x: CGFloat(i) * width + (drawingConfig.size.width - diameter) / 2,
          y: y + (drawingConfig.size.height - diameter) / 2,
          width: diameter,
          height: diameter)
          .insetBy(dx: 4,
                   dy: 4)
        contextRef.setFillColor(UIColor.white.cgColor)

        switch keyframe {
        case .position:
          contextRef.fillEllipse(in: keyframeMarkerRect)
        case .fadeIn:
          contextRef.addPath(fadeInMarkerPath(center: CGPoint(x: keyframeMarkerRect.midX - 1, y: keyframeMarkerRect.midY),
                                              radius: diameter / 2 - 4).cgPath)
          contextRef.fillPath()
        case .fadeOut:
          contextRef.addPath(fadeOutMarkerPath(center: CGPoint(x: keyframeMarkerRect.midX + 1, y: keyframeMarkerRect.midY),
                                              radius: diameter / 2 - 4).cgPath)
          contextRef.fillPath()
        }
      }
    }
  }
  
  func fadeInMarkerPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
    let path = UIBezierPath()
    path.move(to: center)
    path.addArc(withCenter: center,
                radius: radius,
                startAngle: CGFloat(Double.pi) / 2,
                endAngle: CGFloat(Double.pi) * 1.5,
                clockwise: false
    )
    path.close()
    return path
  }
  
  func fadeOutMarkerPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
    let path = UIBezierPath()
    path.move(to: center)
    path.addArc(withCenter: center,
                radius: radius,
                startAngle: CGFloat(Double.pi) / 2,
                endAngle: CGFloat(Double.pi) * 1.5,
                clockwise: true
    )
    path.close()
    return path
  }
}

class HighlightedKeyframeView: UIView {
  let drawingConfig: TimelineViewDrawConfig
  var offset: CGFloat = 0
  
  init(drawingConfig: TimelineViewDrawConfig) {
    self.drawingConfig = drawingConfig
    super.init(frame: .zero)
    isOpaque = false
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    guard let contextRef = UIGraphicsGetCurrentContext() else {
      return
    }
    
    let y = (bounds.height - drawingConfig.size.height) / 2
    let width = drawingConfig.size.width + drawingConfig.spacing
    
    let highlightWindowRect = CGRect(
      origin: CGPoint(x: min(max(0, offset), bounds.width - width), y: y),
      size: drawingConfig.size
    ).insetBy(dx: 2, dy: 2)
    let highlightedPath = CGPath(roundedRect: highlightWindowRect,
                                 cornerWidth: 5,
                                 cornerHeight: 5,
                                 transform: nil)
    contextRef.addPath(highlightedPath)
    contextRef.setLineWidth(2)
    contextRef.setStrokeColor(UIColor.white.cgColor)
    contextRef.strokePath()
  }
}

protocol ScrollableTimelineViewDelegate: AnyObject {
  func scrollableTimelineViewDidScrollToKeyframe(keyframe: Int)
  func scrollableTimelineViewWillBeginDragging()
  func scrollableTimelineViewWillEndDragging()
}

class ScrollableTimelineView: UIView {
  let contentView: TimelineView
  var highlightedKeyframeView: HighlightedKeyframeView
  let drawingConfig: TimelineViewDrawConfig
  let scrollView = UIScrollView()
  var previouslyClickedKeyframeIndex: Int = -1
  var currentKeyframe = 0
  weak var delegate: ScrollableTimelineViewDelegate?
  
  var numberOfKeyframes: Int = 0
  
  override init(frame: CGRect) {
    drawingConfig = TimelineViewDrawConfig(size: CGSize(width: 14, height: 34),
                                           spacing: 5)
    contentView = TimelineView(drawingConfig: drawingConfig)
    highlightedKeyframeView = HighlightedKeyframeView(drawingConfig: drawingConfig)
    super.init(frame: frame)
    scrollView.alwaysBounceHorizontal = true
    scrollView.isScrollEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.isDirectionalLockEnabled = true
    scrollView.addSubview(contentView)
    scrollView.delegate = self
    addSubview(scrollView)
    highlightedKeyframeView.isUserInteractionEnabled = false
    addSubview(highlightedKeyframeView)
    backgroundColor = .black
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    scrollView.frame = bounds
    let contentSize = CGSize(
      width: CGFloat(numberOfKeyframes) * (drawingConfig.size.width + drawingConfig.spacing),
      height: bounds.height)
    scrollView.contentSize = contentSize
    contentView.frame = CGRect(origin: .zero, size: contentSize)
    scrollView.contentInset = UIEdgeInsets(
      top: 0,
      left: bounds.width / 2 - drawingConfig.size.width / 2,
      bottom: 0,
      right: bounds.width / 2 - (drawingConfig.size.width + drawingConfig.spacing))
    if scrollView.contentOffset == .zero {
      scrollView.contentOffset = CGPoint(x: -bounds.width / 2, y: 0)
    }
    highlightedKeyframeView.frame = CGRect(
      x: bounds.width / 2 - drawingConfig.size.width / 2,
      y: 0,
      width: bounds.width / 2,
      height: bounds.height
    )
    highlightedKeyframeView.setNeedsDisplay()
    contentView.setNeedsDisplay()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ScrollableTimelineView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let maxOffset = max(0, scrollView.contentOffset.x + scrollView.contentInset.left)
    contentView.offset = min(maxOffset, scrollView.contentSize.width)
    contentView.setNeedsDisplay()
    
    let width = drawingConfig.size.width + drawingConfig.spacing
    let keyframeIndex = Int(floor(contentView.offset / width))
    
    if previouslyClickedKeyframeIndex != keyframeIndex {
      previouslyClickedKeyframeIndex = keyframeIndex
      delegate?.scrollableTimelineViewDidScrollToKeyframe(keyframe: Int(keyframeIndex))
    }
  }
  
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    let width = drawingConfig.size.width + drawingConfig.spacing
    let keyframeIndex = floor(contentView.offset / width)
    delegate?.scrollableTimelineViewDidScrollToKeyframe(keyframe: Int(keyframeIndex))
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollToNearKeyframe()
  }
  
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    delegate?.scrollableTimelineViewWillBeginDragging()
  }
  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    delegate?.scrollableTimelineViewWillEndDragging()
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      scrollToNearKeyframe()
    }
  }
  
  func scrollToNearKeyframe() {
    let width = drawingConfig.size.width + drawingConfig.spacing
    let contentViewOffset = scrollView.contentOffset.x + scrollView.contentInset.left
    let keyframe = Int((contentViewOffset / width).rounded(.toNearestOrEven))
    scrollToKeyframe(keyframe: keyframe, animated: true, forceUpdate: true)
  }
  
  func scrollToKeyframe(keyframe: Int, animated: Bool = false, forceUpdate: Bool = false) {
    guard previouslyClickedKeyframeIndex != keyframe || forceUpdate else {
      return
    }
    previouslyClickedKeyframeIndex = keyframe
    let width = drawingConfig.size.width + drawingConfig.spacing
    let offset = CGFloat(keyframe) * width - scrollView.contentInset.left
    UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: .allowUserInteraction) { [weak self] in
      self?.scrollView.contentOffset = CGPoint(x: offset, y: 0)
    } completion: { _ in
      self.scrollViewDidEndScrollingAnimation(self.scrollView)
    }
  }
}
