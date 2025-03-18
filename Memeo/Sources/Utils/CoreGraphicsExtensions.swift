//
//  CoreGraphicsExtensions.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//  Renamed from CGPointExtensions.swift to reflect expanded scope
//

import CoreGraphics
import Foundation

extension CGPoint {
    static func + (left: Self, right: Self) -> Self {
        CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: Self, right: Self) -> Self {
        CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
