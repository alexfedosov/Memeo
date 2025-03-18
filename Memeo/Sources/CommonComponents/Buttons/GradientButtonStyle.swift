//
//  GradientButtonStyle.swift
//  Memeo
//
//  Created on 18.3.2025.
//

import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    var gradientColors: [Color]
    var textColor: Color = .white
    var fontWeight: Font.Weight = .bold
    var fontSize: CGFloat = 14
    var horizontalPadding: CGFloat = 24
    var verticalPadding: CGFloat = 8
    var cornerRadius: CGFloat = 7
    var fullWidth: Bool = false
    
    init(
        gradientColors: [Color]? = nil,
        textColor: Color = .white,
        fontWeight: Font.Weight = .bold,
        fontSize: CGFloat = 14,
        horizontalPadding: CGFloat = 24,
        verticalPadding: CGFloat = 8,
        cornerRadius: CGFloat = 7,
        fullWidth: Bool = false
    ) {
        self.gradientColors = gradientColors ?? GradientFactory.primaryColors().reversed()
        self.textColor = textColor
        self.fontWeight = fontWeight
        self.fontSize = fontSize
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.cornerRadius = cornerRadius
        self.fullWidth = fullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor)
            .font(.system(size: fontSize, weight: fontWeight))
            .padding(EdgeInsets(
                top: verticalPadding,
                leading: horizontalPadding,
                bottom: verticalPadding,
                trailing: horizontalPadding
            ))
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GradientButtonStyle {
    /// Standard button style with default settings and primary gradient
    static var gradient: GradientButtonStyle {
        GradientButtonStyle()
    }
    
    /// Full-width button with primary gradient
    static var gradientFullWidth: GradientButtonStyle {
        GradientButtonStyle(fullWidth: true)
    }
    
    /// Dialog-style button with larger padding and full width
    static var gradientDialog: GradientButtonStyle {
        GradientButtonStyle(
            horizontalPadding: 48,
            verticalPadding: 16,
            fullWidth: true
        )
    }
}

struct GradientButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button("Standard Button") {}
                .buttonStyle(.gradient)
            
            Button("Full Width Button") {}
                .buttonStyle(.gradientFullWidth)
            
            Button("Dialog Button") {}
                .buttonStyle(.gradientDialog)
            
            Button("Custom Button") {}
                .buttonStyle(GradientButtonStyle(
                    gradientColors: [.blue, .purple],
                    textColor: .white,
                    fontSize: 16,
                    horizontalPadding: 30,
                    verticalPadding: 10,
                    cornerRadius: 15
                ))
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}