//
//  Tracker.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import CoreGraphics

struct Point: Codable, Hashable {
  var x: Float
  var y: Float
}

extension Point: AnimatedValue {
  func toAnimated() -> Any {
    CGPoint(x: CGFloat(x), y: CGFloat(y)) as Any
  }
}

struct Tracker: Identifiable, Equatable, Codable, Hashable {
  var id: UUID
  var text: String
  
  var position: Animation<Point>
}
