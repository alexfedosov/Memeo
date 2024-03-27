//
//  DialogGradientButton.swift
//  Memeo
//
//  Created by Alex on 12.9.2021.
//

import SwiftUI

struct DialogGradientButton: View {
    let text: String
    let action: () -> Void

    let gradientColors = [
        Color(red: 50 / 255, green: 197 / 255, blue: 1),
        Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
        Color(red: 247 / 255, green: 181 / 255, blue: 0),
    ]

    var body: some View {
        Button(
            action: action,
            label: {
                Text(text)
                    .foregroundColor(.white)
                    .font(Font.system(size: 14, weight: .bold))
                    .padding(EdgeInsets(top: 16, leading: 48, bottom: 16, trailing: 48))
                    .cornerRadius(7)
                    .frame(maxWidth: .infinity)
            }
        ).background(
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors.reversed()),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing))
        )
    }
}

struct DialogGradientButton_Previews: PreviewProvider {
    static var previews: some View {
        DialogGradientButton(text: "Preview", action: {})
    }
}
