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
  @ObservedObject var viewModel: VideoEditorViewModel  
  let onClose: () -> ()
  
  var selectedTracker: Tracker? {
    get {
      if let index = viewModel.selectedTrackerIndex,
         index < viewModel.document.trackers.count {
        return viewModel.document.trackers[index]
      } else {
        return nil
      }
    }
  }
  
  var highlightedKeyframes: Set<Int> {
    get {
      if let keys = selectedTracker?.position.keyframes.keys {
        return Set(keys)
      } else {
        return Set()
      }
    }
  }
  
  var body: some View {
    ZStack {
      VStack {
        HStack {
          Button(action: {
            viewModel
              .documentService
              .save(document: viewModel.document)
              .sink(receiveCompletion: { _ in
                onClose()
              }, receiveValue: { _ in })
              .store(in: &viewModel.cancellables)
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
          if let text = viewModel.lastActionDescription {
            Text(text)
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(.white)
              .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
              .background(RoundedRectangle(cornerRadius: .infinity).fill(Color.white.opacity(0.05)))
              .opacity(0.7)
              .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
          }
          Spacer()
          Button(action: {
            viewModel.showExportingOptionsDialog = true
          }, label: {
            ZStack {
              Image(systemName: "square.and.arrow.up")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
            }
          })
        }
        Spacer()
        EmptyView()
        Spacer()
        TrackerEditorView(trackers: viewModel.document.trackers,
                          numberOfKeyframes: viewModel.document.numberOfKeyframes,
                          currentKeyframe: viewModel.currentKeyframe,
                          isPlaying: viewModel.isPlaying,
                          duration: viewModel.document.duration)
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
        timeline()
        VideoEditorToolbar(isPlaying: viewModel.isPlaying, onSubmitAction: viewModel.submit)
      }.ignoresSafeArea(.keyboard, edges: .bottom)
      trackerTextEditor()
      ZStack {
        VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
          .ignoresSafeArea()
        HStack {
          Text("Exporting your video").font(.title3)
          ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
        }.padding()
      }
      .opacity(viewModel.showExportingVideoModal ? 1: 0)
      .actionSheet(isPresented: $viewModel.showExportingOptionsDialog) {
        ActionSheet(
          title: Text(""),
          message: Text("Would you like to share video or meme template?"),
          buttons: [
            .default(Text("Share video")) {viewModel.exportVideo()},
            .default(Text("Share template")) {viewModel.exportTemplate()},
            .cancel()
          ]
        )
      }
    }
  }
  
  func timeline() -> some View {
    ZStack {
      HStack {
        ZStack {
          Timeline(currentKeyframe: $viewModel.currentKeyframe,
                   isPlaying: $viewModel.isPlaying,
                   numberOfKeyframes: viewModel.document.numberOfKeyframes,
                   higlightedKeyframes: highlightedKeyframes)
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
      HStack{
        Text(selectedTracker?.uiText ?? "")
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
    }
  }
}
