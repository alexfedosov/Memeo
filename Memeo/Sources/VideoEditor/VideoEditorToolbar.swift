//
//  VideoEditorToolbar.swift
//  Memeo
//
//  Created by Alex on 1.9.2021.
//

import SwiftUI

struct VideoEditorToolBarIcon: ViewModifier {
  
  struct Background: ViewModifier {
    func body(content: Content) -> some View {
      content.background(Circle().fill(Color.white.opacity(0.1)))
    }
  }
  
  let hasBackground: Bool
  
  func body(content: Content) -> some View {
    if hasBackground {
      content
        .foregroundColor(.white)
        .font(.subheadline)
        .padding()
        .modifier(Background())
    } else {
      content
        .foregroundColor(.white)
        .font(.subheadline)
        .padding()
    }
  }
}

extension Image {
  func applyToolBarStyle(hasBackground: Bool = true) -> some View {
    self.modifier(VideoEditorToolBarIcon(hasBackground: hasBackground))
  }
}

struct VideoEditorToolbar: View {
  let isPlaying: Bool
  let submitAction: (VideoEditorViewModel.Action) -> Void
  
  init(isPlaying: Bool, onSubmitAction submitAction: @escaping (VideoEditorViewModel.Action) -> Void) {
    self.isPlaying = isPlaying
    self.submitAction = submitAction
  }
  
  var body: some View {
    VStack {
      HStack {
        Button(action: {
          submitAction(.addTracker)
        }, label: {
          Image(systemName: "plus.viewfinder").applyToolBarStyle()
        })
        Button(action: {
          submitAction(.editTracker)
        }, label: {
          Image(systemName: "pencil").applyToolBarStyle()
        })
        Button(action: {
          submitAction(.deleteCurrentKeyframe)
        }, label: {
          Image(systemName: "minus.circle.fill").applyToolBarStyle()
        })
        Button(action: {
          submitAction(.duplicateCurrentKeyframe)
        }, label: {
          ZStack {
            Image(systemName: "circle")
              .applyToolBarStyle(hasBackground: false)
              .offset(x: -2.5, y: -2.5)
            Image(systemName: "circle.fill")
              .applyToolBarStyle(hasBackground: false)
              .offset(x: 2.5, y: 2.5)
          }.modifier(VideoEditorToolBarIcon.Background())
        })
      }.padding()
    }
  }
}

struct VideoEditorToolbar_Previews: PreviewProvider {
  static var previews: some View {
    VideoEditorToolbar(isPlaying: false) { _ in
      
    }
  }
}
