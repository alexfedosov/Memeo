//
//  Animation.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import QuartzCore

protocol AnimatedValue: Codable & Hashable {
  func toAnimated() -> Any
}

struct Animation<T: AnimatedValue>: Identifiable, Equatable, Codable, Hashable {
  var id = UUID()
  var keyframes: [Int: T] = [:]
  var key = ""
}

extension Animation where T == CGPoint {
  func makeCAAnimation(numberOfKeyframes: Int, currentKeyframe: Int, duration: CFTimeInterval, speed: Float, frameSize: CGSize) -> CAKeyframeAnimation {
    let animation = CAKeyframeAnimation(keyPath: key)
    animation.duration = duration
    let keys = keyframes.keys.sorted()
    animation.values = keys
      .compactMap { keyframes[$0] }
      .map { CGPoint(x: frameSize.width * $0.x, y: frameSize.height * $0.y )}
    animation.keyTimes = keys.map {
      Double($0) / Double(numberOfKeyframes) as NSNumber
    }
    
    if let first = animation.values?.first, !keys.contains(0)   {
      animation.values?.insert(first, at: 0)
      animation.keyTimes?.insert(0, at: 0)
    }
    
    if let last = animation.values?.last, !keys.contains(numberOfKeyframes - 1)   {
      animation.values?.append(last)
      animation.keyTimes?.append(NSNumber(value: duration))
    }
    
    animation.timeOffset = duration / Double(numberOfKeyframes) * Double(currentKeyframe)
    animation.speed = speed
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    return animation
  }
  
}
