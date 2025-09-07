//
//  FullscreenModifier.swift
//  Memeo
//
//  Created by Alex on 12.9.2021.
//

import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        let insertion =
            AnyTransition
            .move(edge: .bottom)
            .combined(with: .opacity)
        let removal =
            AnyTransition
            .move(edge: .bottom)
            .combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

struct FullscreenModifier<T: View>: ViewModifier {
    let presenting: T
    let canCancelByBackgroundTap: Bool
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            ZStack {
                if isPresented {
                    VisualEffectView(effect: UIBlurEffect(style: .prominent)).opacity(0.6).ignoresSafeArea()
                        .transition(.opacity)
                    Rectangle().fill(Color.black.opacity(0.6)).ignoresSafeArea()
                        .onTapGesture {
                            if canCancelByBackgroundTap {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                        .transition(.opacity)
                    presenting.transition(.moveAndFade)
                }
            }
        }
    }
}
