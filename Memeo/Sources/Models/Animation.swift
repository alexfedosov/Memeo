//
//  Animation.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import QuartzCore
import AVKit

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
    
    if animation.keyTimes?.isEmpty ?? true {
      animation.keyTimes = [0]
      animation.values = [CGPoint(x: frameSize.width * 0.5, y: frameSize.height * 0.5)]
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

extension Animation where T == Bool {
  func toAnimatedValue(value: Bool, isPlaying: Bool) -> NSNumber {
    min((value ? 1 : 0) + (isPlaying ? 0 : 0.2), 1) as NSNumber
  }
  
  func makeCAAnimation(numberOfKeyframes: Int, currentKeyframe: Int, duration: CFTimeInterval, speed: Float, isPlaying: Bool) -> CAKeyframeAnimation {
    let animation = CAKeyframeAnimation(keyPath: key)
    let fadeTime = 0.03 / duration
    animation.duration = duration
    let keys = keyframes.keys.sorted()
    let animationData = keys
      .map { (time: Double($0 + (keyframes[$0] == true  ? 0 : 0)) / Double(numberOfKeyframes),
              value: keyframes[$0]) }

    var values: [Any] = []
    var keyTimes: [NSNumber] = []
    
    for (index, data) in animationData.enumerated() {
      guard let prevValue = index > 0 ? animationData[index - 1].value : true,
            let value = data.value else { continue }
      
      let time = data.time
      
      if time > 0 {
        values.append(toAnimatedValue(value: prevValue, isPlaying: isPlaying))
        keyTimes.append((time - fadeTime) as NSNumber)
      }
      values.append(toAnimatedValue(value: value, isPlaying: isPlaying))
      keyTimes.append(time as NSNumber)
    }
    
    if values.isEmpty {
      keyTimes = [0]
      values = [1]
    }
    
    if let first = animation.values?.first, !keys.contains(0)   {
      animation.values?.insert(first, at: 0)
      animation.keyTimes?.insert(0, at: 0)
    }

    if let last = animation.values?.last, !keys.contains(numberOfKeyframes - 1)   {
      animation.values?.append(last)
      animation.keyTimes?.append(NSNumber(value: duration))
    }
    animation.keyTimes = keyTimes
    animation.values = values
    animation.timeOffset = duration / Double(numberOfKeyframes) * Double(currentKeyframe)
    animation.speed = speed
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    return animation
  }
}
