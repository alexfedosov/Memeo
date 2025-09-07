//
//  GradientFactory.swift
//  Memeo
//
//  Created on 18.3.2025.
//

import SwiftUI

enum GradientFactory {
    /// Primary gradient used throughout the app (blue, purple, yellow)
    static func primaryGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 50 / 255, green: 197 / 255, blue: 1),
                Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
                Color(red: 247 / 255, green: 181 / 255, blue: 0),
            ].reversed()),
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }
    
    /// Provides primary gradient colors as an array, useful for custom gradients
    static func primaryColors() -> [Color] {
        [
            Color(red: 50 / 255, green: 197 / 255, blue: 1),
            Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
            Color(red: 247 / 255, green: 181 / 255, blue: 0),
        ]
    }
    
    /// Horizontal fade-out gradient (left to right)
    static func horizontalFadeOutGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Horizontal fade-in gradient (right to left)
    static func horizontalFadeInGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, Color.black]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}