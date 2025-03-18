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
                mainEditorContent(geometry)
                TrackerTextEditorContainer(viewModel: viewModel)
                
                // Using the conditional modifier approach for demonstration
                if isExporting {
                    ZStack {
                        VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                            .ignoresSafeArea()
                        HStack {
                            Text("Exporting your video").font(.title3)
                            ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
                        }.padding()
                    }
                }
                
                shareContent()
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
    private func mainEditorContent(_ geometry: GeometryProxy) -> some View {
        VStack {
            VideoEditorHeaderView(viewModel: viewModel, onClose: onClose)
            actionDescriptionView()
            Spacer()
            EmptyView()
            Spacer()
            editorVideoView()
            Spacer()
            PlaybackControls(isPlaying: viewModel.isPlaying, onSubmitAction: viewModel.submit)
            Spacer()
            timelineAndToolbarView(geometry)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ViewBuilder
    private func actionDescriptionView() -> some View {
        Text(viewModel.lastActionDescription ?? "")
            .frame(height: 12)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .opacity(0.7)
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
    }
    
    @ViewBuilder
    private func editorVideoView() -> some View {
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
    }
    
    @ViewBuilder
    private func timelineAndToolbarView(_ geometry: GeometryProxy) -> some View {
        VStack {
            TimelineContainerView(viewModel: viewModel)
            
            VideoEditorToolbar(
                isPlaying: viewModel.isPlaying, 
                canFadeIn: viewModel.canFadeInCurrentKeyframe,
                onSubmitAction: viewModel.submit
            )
            .frame(width: geometry.size.width)
        }
    }
    
    @ViewBuilder
    private func exportingOverlay() -> some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                .ignoresSafeArea()
            HStack {
                Text("Exporting your video").font(.title3)
                ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
            }.padding()
        }
            .opacity((viewModel.isShowingInterstitialAd || viewModel.isExportingVideo) ? 1 : 0)
    }
    
    // Alternative implementation using the conditional modifier
    // This shows how the same functionality could be implemented differently
    private var isExporting: Bool {
        viewModel.isShowingInterstitialAd || viewModel.isExportingVideo
    }
    
    @ViewBuilder
    private func shareContent() -> some View {
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
                    muted: viewModel.isShowingInterstitialAd)
            )
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
