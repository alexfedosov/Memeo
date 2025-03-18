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
    // For the new environment-based approach
    @EnvironmentObject private var environmentViewModel: VideoEditorViewModel
    
    // For backward compatibility with direct initialization
    private var directViewModel: VideoEditorViewModel?
    
    @State private var displayPaywall = false
    let onClose: () -> Void
    
    // Computed property that prioritizes the direct viewModel if provided,
    // otherwise falls back to the environment object
    private var viewModel: VideoEditorViewModel {
        directViewModel ?? environmentViewModel
    }
    
    init(viewModel: VideoEditorViewModel? = nil, onClose: @escaping () -> Void) {
        self.directViewModel = viewModel
        self.onClose = onClose
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    VideoEditorHeaderView(viewModel: viewModel, onClose: onClose)
                    
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
                        TimelineContainerView(viewModel: viewModel)
                        
                        VideoEditorToolbar(
                            isPlaying: viewModel.isPlaying, 
                            canFadeIn: viewModel.canFadeInCurrentKeyframe,
                            onSubmitAction: viewModel.submit
                        )
                        .frame(width: geometry.size.width)
                    }
                }.ignoresSafeArea(.keyboard, edges: .bottom)
                
                TrackerTextEditorContainer(viewModel: viewModel)
                
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

}



struct ContentView_Previews: PreviewProvider {
    static var model = VideoEditorViewModel.preview
    static var previews: some View {
        Group {
            VideoEditor(onClose: {})
                .environmentObject(model)
                .background(Color.black)
                .colorScheme(.dark)
            VideoEditor(onClose: {})
                .environmentObject(model)
                .previewDevice("iPhone 12 mini")
                .background(Color.black)
                .colorScheme(.dark)
            VideoEditor(onClose: {})
                .environmentObject(model)
                .previewDevice("iPhone 12 Pro Max")
                .background(Color.black)
                .colorScheme(.dark)
        }
    }
}
