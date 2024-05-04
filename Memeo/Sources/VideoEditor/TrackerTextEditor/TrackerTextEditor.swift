//
//  TrackerTextEditor.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI

struct TrackerTextEditorResult {
    let text: String
    let style: TrackerStyle
    let size: TrackerSize
}

struct TrackerTextEditor: View {
    @State var text: String
    @State var style: TrackerStyle
    @State var size: TrackerSize
    @State var isTextFieldFocused = true
    let onFinishEditing: (TrackerTextEditorResult) -> Void
    let onDeleteTracker: () -> Void
    @State var showRemoveConfirmation = false

    let styles = [TrackerStyle.transparent, TrackerStyle.black, TrackerStyle.white]
    let sizes = [TrackerSize.small, TrackerSize.medium, TrackerSize.large, TrackerSize.extralarge]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(
                    action: {
                        withAnimation {
                            showRemoveConfirmation = true
                        }
                    },
                    label: {
                        Image(systemName: "trash")
                    }
                )
                .padding(8)
                .foregroundColor(.white)
                .background(Color.red).clipShape(.rect(cornerRadius: 8))
            }
            .font(.system(size: 14, weight: .bold))
            .padding()
            Spacer()
            VStack {
                UIKitTextField(
                    text: $text,
                    isFirstResponder: $isTextFieldFocused
                ) { textField in
                    textField.textAlignment = .center
                    textField.font = .systemFont(ofSize: CGFloat(size.rawValue + 1), weight: .bold)
                    textField.autocorrectionType = .no
                    textField.autocapitalizationType = .none
                }
                .padding()
                .frame(height: 60)
            }.frame(maxHeight: .infinity, alignment: .center)
            HStack {
                Button(
                    action: {
                        withAnimation {
                            style.toggle()
                        }
                    },
                    label: {
                        Text(style.styleName())
                            .foregroundColor(Color(uiColor: style.foregroundColor()))
                            .padding(8)
                            .background(
                                Rectangle()
                                    .fill(Color(uiColor: style.backgroundColor()))
                                    .background(.thinMaterial).clipShape(.rect(cornerRadius: 8))
                        )
                    }
                )
                Button(
                    action: {
                        withAnimation {
                            size.toggle()
                        }
                    },
                    label: {
                        Text(size.styleName())
                            .foregroundColor(Color(uiColor: .white))
                            .padding(8)
                            .background(
                                Rectangle()
                                    .fill(Color(uiColor: .black))
                                    .background(.thinMaterial).clipShape(.rect(cornerRadius: 8))

                            )
                    }
                )
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal)
            HStack {
                Button(
                    action: {
                        isTextFieldFocused = false
                        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        DispatchQueue.main.async {
                            onFinishEditing(.init(text: text, style: style, size: size))
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
            size: .small,
            onFinishEditing: { _ in },
            onDeleteTracker: {}
        )
        .background(Color.black)
        .colorScheme(.dark)
    }
}
