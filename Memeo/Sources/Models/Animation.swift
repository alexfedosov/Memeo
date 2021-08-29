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

extension Animation {
  func makeCAAnimation(numberOfKeyframes: Int, currentKeyframe: Int, duration: CFTimeInterval, speed: Float) -> CAKeyframeAnimation {
    let animation = CAKeyframeAnimation(keyPath: key)
    animation.duration = duration
    let keys = keyframes.keys.sorted()
    animation.values = keys.map {
      keyframes[$0]?.toAnimated() as Any
    }
    animation.keyTimes = keys.map {
      Double($0) / Double(numberOfKeyframes) as NSNumber
    }
    animation.timeOffset = duration / Double(numberOfKeyframes) * Double(currentKeyframe)
    animation.speed = speed
    animation.isRemovedOnCompletion = false
    animation.fillMode = .forwards
    return animation
  }

}
