//
//  TimelineContainerView.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import SwiftUI

struct TimelineContainerView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    
    var body: some View {
        ZStack {
            HStack {
                ZStack {
                    Timeline(
                        currentKeyframe: Binding(
                            get: { viewModel.currentKeyframe },
                            set: { newValue in
                                if viewModel.isPlaying {
                                    viewModel.setIsPlaying(false)
                                }
                                // This is a workaround since we can't directly set currentKeyframe
                                if newValue > viewModel.currentKeyframe {
                                    viewModel.submit(action: .goForward(frames: newValue - viewModel.currentKeyframe))
                                } else if newValue < viewModel.currentKeyframe {
                                    viewModel.submit(action: .goBack(frames: viewModel.currentKeyframe - newValue))
                                }
                            }
                        ),
                        isPlaying: Binding(
                            get: { viewModel.isPlaying },
                            set: { viewModel.setIsPlaying($0) }
                        ),
                        numberOfKeyframes: Binding(
                            get: { viewModel.document.numberOfKeyframes },
                            set: { _ in } // Read-only binding
                        ),
                        highlightedKeyframes: viewModel.highlightedKeyframes)
                    HStack {
                        GradientFactory.horizontalFadeOutGradient()
                            .frame(width: 40)
                        Spacer()
                        GradientFactory.horizontalFadeInGradient()
                            .frame(width: 40)
                    }
                }
                .frame(height: 80)
            }
            HStack {
                Text(viewModel.selectedTracker?.uiText ?? "")
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.3)
                    .offset(x: 0, y: -40)
                Spacer()
                Text("\(viewModel.currentKeyframe + 1)/\(viewModel.document.numberOfKeyframes)")
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.3)
                    .offset(x: 0, y: -40)
            }.padding()
        }
    }
}

struct TimelineContainerView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineContainerView(viewModel: VideoEditorViewModel.preview)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}