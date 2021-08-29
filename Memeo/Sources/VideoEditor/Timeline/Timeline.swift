//
//  Timeline.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import SwiftUI
import UIKit

struct Timeline: UIViewRepresentable {
  @Binding var currentKeyframe: Int
  @Binding var isPlaying: Bool
  @State var numberOfKeyframes: Int
  var higlightedKeyframes: Set<Int>

  func updateUIView(
    _ uiView: ScrollableTimelineView,
    context: Context
  ) {
    if isPlaying {
      uiView.scrollToKeyframe(keyframe: currentKeyframe)
    }

    if numberOfKeyframes != uiView.numberOfKeyframes {
      uiView.numberOfKeyframes = numberOfKeyframes
      uiView.contentView.setNeedsDisplay()
      uiView.setNeedsDisplay()
      uiView.scrollToNearKeyframe()
    }

    if higlightedKeyframes != uiView.contentView.keyframes {
      uiView.contentView.keyframes = higlightedKeyframes
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
    private var wasPlaying = false

    let generator = UIImpactFeedbackGenerator()

    init(currentKeyframe: Binding<Int>, numberOfKeyframes: Binding<Int>, isPlaying: Binding<Bool>) {
      _currentKeyframe = currentKeyframe
      _numberOfKeyframes = numberOfKeyframes
      _isPlaying = isPlaying
      generator.prepare()
    }
    
    func scrollableTimelineViewDidScrollToKeyframe(keyframe: Int) {
      currentKeyframe = max(0, min(keyframe, numberOfKeyframes - 1))
      generator.impactOccurred(intensity: 0.5)
      generator.prepare()
    }
    
    func scrollableTimelineViewWillBeginDragging() {
      wasPlaying = isPlaying
      isPlaying = false
    }
    
    func scrollableTimelineViewWillEndDragging() {
      isPlaying = wasPlaying
    }
  }
}

struct Timeline_Previews: PreviewProvider {
  static var model = VideoEditorViewModel(document: Document.loadPreviewDocument())
  static var previews: some View {
    let keyframes = Set(model.document.trackers.first!.position.keyframes.keys)
    return VStack {
      Timeline(currentKeyframe: .constant(10),
               isPlaying: .constant(false),
               numberOfKeyframes: model.document.numberOfKeyframes,
               higlightedKeyframes: keyframes)
        .frame(height: 64)
        .frame(maxWidth: .greatestFiniteMagnitude)
    }.frame(maxWidth: .greatestFiniteMagnitude,
        maxHeight: .greatestFiniteMagnitude)
  }
}
