//
//  Timeline.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import SwiftUI
import UIKit

enum KeyframeType: Int, Hashable {
  case position
  case fadeIn
  case fadeOut
}

struct Timeline: UIViewRepresentable {
  @Binding var currentKeyframe: Int
  @Binding var isPlaying: Bool
  @State var numberOfKeyframes: Int
  var highlightedKeyframes: [Int: KeyframeType]
  
  func updateUIView(
    _ uiView: ScrollableTimelineView,
    context: Context
  ) {
    context.coordinator.currentKeyframe = currentKeyframe
    context.coordinator.numberOfKeyframes = numberOfKeyframes
    context.coordinator.isPlaying = isPlaying
    
    uiView.scrollToKeyframe(keyframe: currentKeyframe)
    
    if numberOfKeyframes != uiView.numberOfKeyframes {
      uiView.numberOfKeyframes = numberOfKeyframes
      uiView.contentView.setNeedsDisplay()
      uiView.setNeedsDisplay()
      uiView.scrollToNearKeyframe()
    }
    
    if highlightedKeyframes != uiView.contentView.highlightedKeyframes {
      uiView.contentView.highlightedKeyframes = highlightedKeyframes
      uiView.contentView.setNeedsDisplay()
    }
  }
  
  func makeUIView(context: Context) -> ScrollableTimelineView {
    let view = ScrollableTimelineView()
    view.delegate = context.coordinator
    return view
  }
  
  func makeCoordinator() -> Coordinator {
    let coordinator = Coordinator()
    coordinator.setKeyframe = { [$currentKeyframe] keyframe in
      $currentKeyframe.wrappedValue = keyframe
    }
    return coordinator
  }
  
  class Coordinator: ScrollableTimelineViewDelegate {
    var currentKeyframe: Int = 0
    var numberOfKeyframes: Int = 0
    var isPlaying: Bool = false
    var setKeyframe: ((Int) -> Void)?
    
    func scrollableTimelineViewDidScrollToKeyframe(keyframe: Int) {
      if keyframe != currentKeyframe {
        setKeyframe?(max(0, min(keyframe, numberOfKeyframes - 1)))
      }
    }
    
    func scrollableTimelineViewWillBeginDragging() {
      isPlaying = false
    }
    
    func scrollableTimelineViewWillEndDragging() {
    }
  }
}

struct Timeline_Previews: PreviewProvider {
  static var model = VideoEditorViewModel.preview
  static var previews: some View {
    return VStack {
      Timeline(currentKeyframe: .constant(model.document.fps),
               isPlaying: .constant(false),
               numberOfKeyframes: model.document.numberOfKeyframes,
               highlightedKeyframes: [:])
        .frame(height: 64)
        .frame(maxWidth: .greatestFiniteMagnitude)
    }.frame(maxWidth: .greatestFiniteMagnitude,
            maxHeight: .greatestFiniteMagnitude)
  }
}
