//
//  Tracker.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import CoreGraphics
import Foundation
import UIKit

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

extension Bool: AnimatedValue {
    func toAnimated() -> Any {
        self
    }
}

enum TrackerStyle: Int, Codable, Identifiable {
    var id: Int {
        self.rawValue
    }

    case transparent = 0
    case black = 1
    case white = 2

    func styleName() -> String {
        switch self {
        case .transparent: "Transparent"
        case .black: "Black"
        case .white: "White"
        }
    }

    func backgroundColor() -> UIColor {
        switch self {
        case .transparent: .clear
        case .black: .black
        case .white: .white
        }
    }

    func foregroundColor() -> UIColor {
        switch self {
        case .transparent: .white
        case .black: .white
        case .white: .black
        }
    }

    mutating func toggle() {
        switch self {
        case .transparent: self = .black
        case .black: self = .white
        case .white: self = .transparent
        }
    }
}

enum TrackerSize: Int, Codable, Identifiable {
    var id: Int {
        self.rawValue
    }

    case extrasmall = 10
    case small = 14
    case medium = 18
    case large = 20
    case extralarge = 24

    func styleName() -> String {
        switch self {
        case .extrasmall: "Extra small"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extralarge: "Extra large"
        }
    }

    mutating func toggle() {
        switch self {
        case .extrasmall:
            self = .small
        case .small:
            self = .medium
        case .medium:
            self = .large
        case .large:
            self = .extralarge
        case .extralarge:
            self = .extrasmall
        }
    }
}

struct Tracker: Identifiable, Equatable, Codable, Hashable {
    var id: UUID
    var text: String
    var style: TrackerStyle
    var size: TrackerSize

    var position: Animation<CGPoint>
    var fade: Animation<Bool>

    var uiText: String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count > 0 ? text : "Double tap to edit"
    }
}
