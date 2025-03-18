//
//  MemeoButton.swift
//  Memeo
//
//  Created on 18.3.2025.
//

import SwiftUI

struct MemeoButton: View {
    let text: String
    let action: () -> Void
    var style: MemeoButtonStyle = .standard
    
    var body: some View {
        Button(action: action) {
            Text(text)
        }
        .buttonStyle(style.buttonStyle)
    }
    
    enum MemeoButtonStyle {
        case standard
        case dialog
        case fullWidth
        case custom(GradientButtonStyle)
        
        var buttonStyle: GradientButtonStyle {
            switch self {
            case .standard:
                return .gradient
            case .dialog:
                return .gradientDialog
            case .fullWidth:
                return .gradientFullWidth
            case .custom(let style):
                return style
            }
        }
    }
}

extension MemeoButton {
    /// Creates a standard gradient button with default styling
    static func standard(text: String, action: @escaping () -> Void) -> MemeoButton {
        MemeoButton(text: text, action: action, style: .standard)
    }
    
    /// Creates a full-width gradient button
    static func fullWidth(text: String, action: @escaping () -> Void) -> MemeoButton {
        MemeoButton(text: text, action: action, style: .fullWidth)
    }
    
    /// Creates a dialog-style gradient button with larger padding and full width
    static func dialog(text: String, action: @escaping () -> Void) -> MemeoButton {
        MemeoButton(text: text, action: action, style: .dialog)
    }
}

struct MemeoButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MemeoButton.standard(text: "Standard Button", action: {})
            
            MemeoButton.fullWidth(text: "Full Width Button", action: {})
            
            MemeoButton.dialog(text: "Dialog Button", action: {})
            
            MemeoButton(
                text: "Custom Button",
                action: {},
                style: .custom(GradientButtonStyle(
                    gradientColors: [.green, .blue],
                    fontSize: 16,
                    horizontalPadding: 32,
                    verticalPadding: 12,
                    cornerRadius: 10
                ))
            )
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}