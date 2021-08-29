//
//  ContentView.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI

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
    VStack {
      Text("selected tracker index \(viewModel.selectedTrackerIndex ?? -1)")
      Text("\(viewModel.currentKeyframe)")
      Text("\(viewModel.document.numberOfKeyframes)")
        .padding()
      HStack {
        Button(action: {
          viewModel.addTracker()
        }, label: {
          Text("Add")
        })
        Button(action: {
          viewModel.removeTracker()
        }, label: {
          Text("Remove")
        })
        Button(action: {
          viewModel.swapFirstAndLastTrackers()
        }, label: {
          Text("Swap")
        })
        Button(action: {
          viewModel.updateText()
        }, label: {
          Text("Update")
        })
        Button(action: {
          viewModel.isPlaying.toggle()
        }, label: {
          Text("Play/Pause")
        })
      }
      TrackerEditorView(trackers: viewModel.document.trackers,
                        numberOfKeyframes: viewModel.document.numberOfKeyframes,
                        currentKeyframe: viewModel.currentKeyframe,
                        isPlaying: viewModel.isPlaying)
        .onTrackerTapped({ tracker in
          viewModel.selectTracker(tracker: tracker)
        })
        .onTrackerPositionChanged({ point, tracker in
          viewModel.changePositionKeyframeValue(tracker: tracker, point: point)
        })
        .background(Color.black)
      Timeline(currentKeyframe: $viewModel.currentKeyframe,
               isPlaying: $viewModel.isPlaying,
               numberOfKeyframes: viewModel.document.numberOfKeyframes,
               higlightedKeyframes: highlightedKeyframes)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var model = VideoEditorViewModel(document: Document.loadPreviewDocument())
  static var previews: some View {
    VideoEditor(viewModel: model)
  }
}
