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
    Coordinator(currentKeyframe: $currentKeyframe, numberOfKeyframes: $numberOfKeyframes, isPlaying: $isPlaying)
  }
  
  class Coordinator: ScrollableTimelineViewDelegate {
    @Binding var currentKeyframe: Int
    @Binding var numberOfKeyframes: Int
    @Binding var isPlaying: Bool

    let generator = UIImpactFeedbackGenerator()

    init(currentKeyframe: Binding<Int>, numberOfKeyframes: Binding<Int>, isPlaying: Binding<Bool>) {
      _currentKeyframe = currentKeyframe
      _numberOfKeyframes = numberOfKeyframes
      _isPlaying = isPlaying
      generator.prepare()
    }
    
    func scrollableTimelineViewDidScrollToKeyframe(keyframe: Int) {
      if keyframe != currentKeyframe {
        currentKeyframe = max(0, min(keyframe, numberOfKeyframes - 1))
      }
      if !isPlaying {
        generator.impactOccurred(intensity: 0.5)
        generator.prepare()
      }
    }
    
    func scrollableTimelineViewWillBeginDragging() {
      isPlaying = false
    }
    
    func scrollableTimelineViewWillEndDragging() {}
  }
}

struct Timeline_Previews: PreviewProvider {
  static var model = VideoEditorViewModel.preview
  static var previews: some View {
//    let keyframes = [0: .fadeInt]
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
