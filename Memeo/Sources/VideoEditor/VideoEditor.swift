//
//  ContentView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine

struct VideoEditor: View {
  @StateObject var viewModel: VideoEditorViewModel
  let onClose: () -> ()
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack {
          HStack {
            Button(action: {
              viewModel.cleanDocumentsDirectory()
              onClose()
            }, label: {
              ZStack {
                Image(systemName: "xmark")
                  .font(.subheadline)
                  .foregroundColor(.white)
                  .padding()
              }
            })
            Spacer()
            Button(action: {
              viewModel.isPlaying = false
              withAnimation {
                viewModel.showHelp = true
              }
            }, label: {
              Image(systemName: "questionmark")
                .font(Font.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .padding(EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
                .background(Color.white.opacity(0.1))
                .cornerRadius(7)
            })
            GradientBorderButton(text: "Share!", action: {
              withAnimation {
                viewModel.share()
              }
            }).padding(.trailing)
          }
          Text(viewModel.lastActionDescription ?? "")
            .frame(height: 12)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .opacity(0.7)
            .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
            .animation(.none)
          Spacer()
          EmptyView()
          Spacer()
          TrackerEditorView(trackers: viewModel.document.trackers,
                            numberOfKeyframes: viewModel.document.numberOfKeyframes,
                            isPlaying: viewModel.isPlaying,
                            selectedTrackerIndex: viewModel.selectedTrackerIndex,
                            duration: viewModel.document.duration,
                            playerItem: viewModel.videoPlayer.currentItem)
            .onTrackerTapped({ tracker in
              viewModel.selectTracker(tracker: tracker)
            })
            .onTrackerDoubleTapped({ tracker in
              viewModel.selectTracker(tracker: tracker)
              viewModel.isEditingText = true
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
            VideoEditorToolbar(isPlaying: viewModel.isPlaying, canFadeIn: viewModel.canFadeInCurrentKeyframe, onSubmitAction: viewModel.submit)
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
          ShareView(viewModel: ShareViewModel(
                      isShown: $viewModel.isShowingShareDialog,
                      videoUrl: viewModel.exportedVideoUrl,
                      gifURL: viewModel.exportedGifUrl,
                      frameSize: viewModel.document.frameSize,
                      muted: viewModel.isShowingInterstitialAd))
        }
        .presentHelpView(isPresented: $viewModel.showHelp)
        .presentInterstitialAd(isPresented: $viewModel.isShowingInterstitialAd, adUnitId: InterstitialAd.adUnit)
      }
    }
  }
  
  @ViewBuilder
  func timeline() -> some View {
    ZStack {
      HStack {
        ZStack {
          Timeline(currentKeyframe: $viewModel.currentKeyframe,
                   isPlaying: $viewModel.isPlaying,
                   numberOfKeyframes: $viewModel.document.numberOfKeyframes,
                   highlightedKeyframes: viewModel.highlightedKeyframes)
          HStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]),
                           startPoint: .leading,
                           endPoint: .trailing)
              .frame(width: 40)
            Spacer()
            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black]),
                           startPoint: .leading,
                           endPoint: .trailing)
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
      if let index = viewModel.selectedTrackerIndex,
         let text = viewModel.document.trackers[index].text,
         viewModel.isEditingText {
        TrackerTextEditor(text: text) { newText in
          viewModel.document.trackers[index].text = newText
          viewModel.isEditingText = false
        } onDeleteTracker: {
          viewModel.isEditingText = false
          viewModel.submit(action: .removeSelectedTracker)
        }.transition(.opacity)
      }
    }
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
