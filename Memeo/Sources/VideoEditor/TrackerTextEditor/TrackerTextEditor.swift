//
//  TrackerTextEditor.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI

struct TrackerTextEditor: View {
    @State var text: String
    @State var style: TrackerStyle
    @State var isTextFieldFocused = true
    let onFinishEditing: (String, TrackerStyle) -> Void
    let onDeleteTracker: () -> Void
    @State var showRemoveConfirmation = false

    let styles = [TrackerStyle.transparent, TrackerStyle.black, TrackerStyle.white]

    var body: some View {
        VStack {
            HStack {
                Button(
                    action: {
                        withAnimation {
                            style.toggle()
                        }
                    },
                    label: {
                        HStack {
                            Text(style.styleName())
                                .foregroundColor(Color(uiColor: style.foregroundColor()))
                        }
                        .padding()
                        .background(
                            Rectangle()
                                .fill(Color(uiColor: style.backgroundColor()))
                                .background(.thinMaterial).clipShape(.capsule)

                        )
                    }
                ).padding()
                Button(
                    action: {
                        withAnimation {
                            showRemoveConfirmation = true
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: .infinity).fill(Color.red))
                    }
                ).padding()
            }
            .font(.system(size: 14, weight: .bold))
            Spacer()
            VStack {
                UIKitTextField(
                    text: $text,
                    isFirstResponder: $isTextFieldFocused
                ) { textField in
                    textField.textAlignment = .center
                    textField.font = .systemFont(ofSize: 16, weight: .bold)
                    textField.autocorrectionType = .no
                    textField.autocapitalizationType = .none
                }
                .padding()
                .frame(height: 60)
            }.frame(maxHeight: .infinity, alignment: .center)
            HStack {
                Button(
                    action: {
                        isTextFieldFocused = false
                        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        DispatchQueue.main.async {
                            onFinishEditing(text, style)
                        }
                    },
                    label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                ).padding()
            }
        }
        .frame(maxHeight: .greatestFiniteMagnitude)
        .background(Material.regular)
        .transition(
            .asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.3)),
                removal: .opacity.animation(.easeOut(duration: 0.15)))
        )
        .alert(
            isPresented: $showRemoveConfirmation,
            content: {
                Alert(
                    title: Text("Delete text?"),
                    message: Text("This will delete text and text animation data"),
                    primaryButton: .destructive(
                        Text("Delete"),
                        action: {
                            onDeleteTracker()
                        }),
                    secondaryButton: .cancel())
            })
    }
}

struct TrackerTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        TrackerTextEditor(
            text: "Tracker 1",
            style: .transparent,
            onFinishEditing: { _, _ in },
            onDeleteTracker: {}
        )
        .background(Color.black)
        .colorScheme(.dark)
    }
}
