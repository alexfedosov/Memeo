//
//  Tracker.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import CoreGraphics

extension CGPoint: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(x)
    hasher.combine(y)
  }
}

extension CGPoint: AnimatedValue {
  func toAnimated() -> Any {
    self
  }
}

struct Tracker: Identifiable, Equatable, Codable, Hashable {
  var id: UUID
  var text: String
  
  var position: Animation<CGPoint>
}
