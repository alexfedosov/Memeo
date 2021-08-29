//
//  CGPointExtentions.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import CoreGraphics

extension CGPoint {
  static func +(left: Self, right: Self) -> Self {
    CGPoint(x: left.x + right.x, y: left.y + right.y)
  }

  static func -(left: Self, right: Self) -> Self {
    CGPoint(x: left.x - right.x, y: left.y - right.y)
  }
}
