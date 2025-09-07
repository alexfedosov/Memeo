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
        VStack {
            HStack(alignment: .lastTextBaseline) {
                Button(
                    action: {
                        submitAction(.addTracker)
                    },
                    label: {
                        VStack {
                            Image(systemName: "textformat").applyToolBarStyle()
                            Text("Add text")
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                                .opacity(0.3)
                                .frame(height: 20)
                        }
                    }
                ).frame(width: 80)
                Button(
                    action: {
                        submitAction(.deleteCurrentKeyframe)
                    },
                    label: {
                        VStack {
                            Image(systemName: "minus.circle.fill").applyToolBarStyle()
                            Text("Delete keyframe")
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                                .opacity(0.3)
                                .frame(height: 20)
                        }
                    }
                ).frame(width: 80)
                Button(
                    action: {
                        submitAction(.duplicateCurrentKeyframe)
                    },
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
                ).frame(width: 80)
                Button(
                    action: {
                        submitAction(canFadeIn ? .fadeInTracker : .fadeOutTracker)
                    },
                    label: {
                        VStack {
                            Image(systemName: canFadeIn ? "eye" : "eye.slash").applyToolBarStyle()
                            Text(canFadeIn ? String(localized: "Show text") : String(localized: "Hide text"))
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                                .opacity(0.3)
                                .frame(height: 20)
                        }
                    }
                ).frame(width: 80)
            }.padding()
        }
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
