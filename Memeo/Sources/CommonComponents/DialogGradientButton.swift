//
//  DialogGradientButton.swift
//  Memeo
//
//  Created by Alex on 12.9.2021.
//  Updated on 18.3.2025.
//

import SwiftUI

/// DialogGradientButton uses the MemeoButton component with a dialog-style preset
/// Use for primary actions in modal dialogs where you want a full-width gradient button
struct DialogGradientButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        MemeoButton(text: text, action: action, style: .dialog)
    }
}

struct DialogGradientButton_Previews: PreviewProvider {
    static var previews: some View {
        DialogGradientButton(text: "Preview", action: {})
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}