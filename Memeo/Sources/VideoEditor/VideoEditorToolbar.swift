//
//  VideoEditorToolbar.swift
//  Memeo
//
//  Created by Alex on 1.9.2021.
//

import SwiftUI

struct VideoEditorToolBarIcon: ViewModifier {

    struct Background: ViewModifier {
        func body(content: Content) -> some View {
            content
                .frame(width: 50, height: 50, alignment: .center)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
    }

    let hasBackground: Bool

    func body(content: Content) -> some View {
        if hasBackground {
            content
                .foregroundColor(.white)
                .font(.subheadline)
                .padding()
                .modifier(Background())
        } else {
            content
                .foregroundColor(.white)
                .font(.subheadline)
                .padding()
        }
    }
}

extension Image {
    func applyToolBarStyle(hasBackground: Bool = true) -> some View {
        self.modifier(VideoEditorToolBarIcon(hasBackground: hasBackground))
    }
}

struct VideoEditorToolbar: View {
    let isPlaying: Bool
    let canFadeIn: Bool
    let submitAction: (VideoEditorViewModel.Action) -> Void

    init(isPlaying: Bool, canFadeIn: Bool, onSubmitAction submitAction: @escaping (VideoEditorViewModel.Action) -> Void)
    {
        self.isPlaying = isPlaying
        self.submitAction = submitAction
        self.canFadeIn = canFadeIn
    }

    var body: some View {
        // Define a more semantic grid layout
        let columns = [
            GridItem(.fixed(80), spacing: 0),
            GridItem(.fixed(80), spacing: 0),
            GridItem(.fixed(80), spacing: 0),
            GridItem(.fixed(80), spacing: 0)
        ]
        
        // Use LazyHGrid for a more semantic layout
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 0) {
                // Add Text Button
                toolbarButton(
                    action: { submitAction(.addTracker) },
                    iconName: "textformat",
                    label: "Add text"
                )
                
                // Delete Keyframe Button
                toolbarButton(
                    action: { submitAction(.deleteCurrentKeyframe) },
                    iconName: "minus.circle.fill",
                    label: "Delete keyframe"
                )
                
                // Copy Keyframe Button
                Button(
                    action: { submitAction(.duplicateCurrentKeyframe) },
                    label: {
                        VStack {
                            ZStack {
                                Image(systemName: "circle")
                                    .applyToolBarStyle(hasBackground: false)
                                    .offset(x: -2.5, y: -2.5)
                                Image(systemName: "circle.fill")
                                    .applyToolBarStyle(hasBackground: false)
                                    .offset(x: 2.5, y: 2.5)
                            }.modifier(VideoEditorToolBarIcon.Background())
                            Text("Copy keyframe")
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                                .opacity(0.3)
                                .frame(height: 20)
                        }
                    }
                )
                .frame(width: 80)
                
                // Show/Hide Text Button
                toolbarButton(
                    action: { submitAction(canFadeIn ? .fadeInTracker : .fadeOutTracker) },
                    iconName: canFadeIn ? "eye" : "eye.slash",
                    label: canFadeIn ? String(localized: "Show text") : String(localized: "Hide text")
                )
            }
            .padding()
        }
        .frame(height: 120)
    }
    
    @ViewBuilder
    private func toolbarButton(action: @escaping () -> Void, iconName: String, label: String) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName).applyToolBarStyle()
                Text(label)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.system(size: 10))
                    .opacity(0.3)
                    .frame(height: 20)
            }
        }
        .frame(width: 80)
    }
}

struct VideoEditorToolbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoEditorToolbar(isPlaying: false, canFadeIn: false) { _ in
            }
            VideoEditorToolbar(isPlaying: false, canFadeIn: false) { _ in
            }
            .previewDevice("iPhone 12 mini")
        }
    }
}
