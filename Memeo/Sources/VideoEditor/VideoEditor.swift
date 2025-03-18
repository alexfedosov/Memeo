//
//  ContentView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import AVFoundation
import AVKit
import Combine
import SwiftUI
import RevenueCat
import RevenueCatUI

struct VideoEditor: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    @State private var displayPaywall = false
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    HStack {
                        Button(
                            action: {
                                viewModel.cleanDocumentsDirectory()
                                onClose()
                            },
                            label: {
                                ZStack {
                                    Image(systemName: "xmark")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            })
                        Spacer()
                        Button(
                            action: {
                                viewModel.setIsPlaying(false)
                                withAnimation {
                                    viewModel.setShowHelp(true)
                                }
                            },
                            label: {
                                Image(systemName: "questionmark")
                                    .font(Font.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(7)
                            })
                        GradientBorderButton(
                            text: String(localized: "Share!"),
                            action: {
                                Task {
//                                    let customerInfo = try? await Purchases.shared.customerInfo()
//                                    displayPaywall = customerInfo?.activeSubscriptions.isEmpty ?? true
//                                    if !displayPaywall {
                                        try? await viewModel.share()
//                                    }
                                }
                            }
                        ).padding(.trailing)
                    }
                    Text(viewModel.lastActionDescription ?? "")
                        .frame(height: 12)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(0.7)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                    Spacer()
                    EmptyView()
                    Spacer()
                    TrackerEditorView(
                        trackers: viewModel.document.trackers,
                        numberOfKeyframes: viewModel.document.numberOfKeyframes,
                        isPlaying: viewModel.isPlaying,
                        selectedTrackerIndex: viewModel.selectedTrackerIndex,
                        duration: viewModel.document.duration,
                        playerItem: viewModel.videoPlayer.currentItem
                    )
                    .onTrackerTapped({ tracker in
                        viewModel.selectTracker(tracker: tracker)
                    })
                    .onTrackerDoubleTapped({ tracker in
                        viewModel.selectTracker(tracker: tracker)
                        viewModel.setIsEditingText(true)
                    })
                    .onTrackerPositionChanged({ point, tracker in
                        viewModel.changePositionKeyframeValue(tracker: tracker, point: point)
                    })
                    .aspectRatio(viewModel.document.frameSize, contentMode: .fit)
                    .background(VideoPlayerView(videoPlayer: viewModel.videoPlayer))
                    Spacer()
                    PlaybackControls(isPlaying: viewModel.isPlaying, onSubmitAction: viewModel.submit)
                    Spacer()
                    VStack {
                        timeline()
                        VideoEditorToolbar(
                            isPlaying: viewModel.isPlaying, 
                            canFadeIn: viewModel.canFadeInCurrentKeyframe,
                            onSubmitAction: viewModel.submit
                        )
                        .frame(width: geometry.size.width)
                    }
                }.ignoresSafeArea(.keyboard, edges: .bottom)
                trackerTextEditor()
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                        .ignoresSafeArea()
                    HStack {
                        Text("Exporting your video").font(.title3)
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
                    }
                    .padding()
                }.opacity((viewModel.isShowingInterstitialAd || viewModel.isExportingVideo) ? 1 : 0)
                ZStack {
                    ShareView(
                        viewModel: ShareViewModel(
                            isShown: Binding(
                                get: { viewModel.isShowingShareDialog },
                                set: { _ in viewModel.closeShareDialog() }
                            ),
                            videoUrl: viewModel.exportedVideoUrl,
                            gifURL: viewModel.exportedGifUrl,
                            frameSize: viewModel.document.frameSize,
                            muted: viewModel.isShowingInterstitialAd))
                }
                .presentHelpView(isPresented: Binding(
                    get: { viewModel.showHelp },
                    set: { viewModel.setShowHelp($0) }
                ))
            }
            .sheet(isPresented: $displayPaywall) {
                PaywallView(displayCloseButton: true)
            }
        }
    }

    @ViewBuilder
    func timeline() -> some View {
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
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)
                        Spacer()
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
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

    func trackerTextEditor() -> some View {
        VStack {
            if let index = viewModel.selectedTrackerIndex, viewModel.isEditingText {
                TrackerTextEditor(
                    text: viewModel.document.trackers[index].text,
                    style: viewModel.document.trackers[index].style,
                    size: viewModel.document.trackers[index].size
                ) { result in
                    viewModel.updateTrackerText(
                        text: result.text,
                        style: result.style,
                        size: result.size
                    )
                } onDeleteTracker: {
                    viewModel.setIsEditingText(false)
                    viewModel.submit(action: .removeSelectedTracker)
                }.transition(.opacity)
            }
        }
    }
}

struct GradientBorderButton: View {
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
                    .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                    .cornerRadius(7)
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


struct ContentView_Previews: PreviewProvider {
    static var model = VideoEditorViewModel.preview
    static var previews: some View {
        Group {
            VideoEditor(viewModel: model, onClose: {})
                .background(Color.black)
                .colorScheme(.dark)
            VideoEditor(viewModel: model, onClose: {})
                .previewDevice("iPhone 12 mini")
                .background(Color.black)
                .colorScheme(.dark)
            VideoEditor(viewModel: model, onClose: {})
                .previewDevice("iPhone 12 Pro Max")
                .background(Color.black)
                .colorScheme(.dark)
        }
    }
}
