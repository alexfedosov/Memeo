//
//  ContentView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI
import AVFoundation

struct VideoEditor: View {
  @ObservedObject var viewModel: VideoEditorViewModel
  
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
        Spacer()
        TrackerEditorView(trackers: viewModel.document.trackers,
                          numberOfKeyframes: viewModel.document.numberOfKeyframes,
                          currentKeyframe: viewModel.currentKeyframe,
                          isPlaying: viewModel.isPlaying,
                          duration: viewModel.document.duration)
          .onTrackerTapped({ tracker in
            viewModel.selectTracker(tracker: tracker)
            viewModel.isEditingText = true
          })
          .onTrackerPositionChanged({ point, tracker in
            viewModel.changePositionKeyframeValue(tracker: tracker, point: point)
          })
          .aspectRatio(viewModel.document.frameSize, contentMode: .fit)
        Spacer()
        ZStack {
          Timeline(currentKeyframe: $viewModel.currentKeyframe,
                   isPlaying: $viewModel.isPlaying,
                   numberOfKeyframes: viewModel.document.numberOfKeyframes,
                   higlightedKeyframes: highlightedKeyframes)
            .frame(height: 100)
          HStack{
            Spacer()
            Text("\(selectedTracker?.text.appending(": ") ?? "")\(viewModel.currentKeyframe + 1)/\(viewModel.document.numberOfKeyframes)")
              .font(.system(size: 10, weight: .bold))
              .opacity(0.3)
              .offset(x: 0, y: -40)
          }.padding()
        }
        .padding(.vertical)
        toolbar()
      }.ignoresSafeArea(.keyboard, edges: .bottom)
      trackerTextEditor()
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
          viewModel.removeSelectedTracker()
        }.transition(.opacity)
      }
    }
  }
  
  func toolbar() -> some View {
    VStack {
      HStack {
        Button(action: {
          viewModel.addTracker()
        }, label: {
          Image(systemName: "plus.viewfinder")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.white.opacity(0.1))
            )
        })
        Button(action: {
          withAnimation {
            viewModel.isPlaying.toggle()
          }
        }, label: {
          Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.white.opacity(0.1))
            )
        })
        Button(action: {
          viewModel.deleteCurrentKeyframe()
        }, label: {
          Image(systemName: "minus.circle.fill")
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.white.opacity(0.1))
            )
        })
        Button(action: {
          viewModel.duplicateCurrentKeyframe()
        }, label: {
          ZStack {
            Image(systemName: "circle")
              .font(.subheadline)
              .foregroundColor(.white)
              .padding()
              .offset(x: -2.5, y: -2.5)
            Image(systemName: "circle.fill")
              .font(.subheadline)
              .foregroundColor(.white)
              .padding()
              .offset(x: 2.5, y: 2.5)
          }.background(Circle().fill(Color.white.opacity(0.1)))
        })
      }.padding()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var model = VideoEditorViewModel(document: Document.loadPreviewDocument())
  static var previews: some View {
    VideoEditor(viewModel: model)
      .background(Color.black)
      .colorScheme(.dark)
  }
}
