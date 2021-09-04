//
//  PlaybackControls.swift
//  Memeo
//
//  Created by Alex on 1.9.2021.
//

import SwiftUI

struct PlaybackControls: View {
  let isPlaying: Bool
  let submitAction: (VideoEditorViewModel.Action) -> Void
  
  init(isPlaying: Bool, onSubmitAction submitAction: @escaping (VideoEditorViewModel.Action) -> Void) {
    self.isPlaying = isPlaying
    self.submitAction = submitAction
  }
  
  var body: some View {
    HStack {
      Button(action: {
        withAnimation {
          submitAction(.preview)
        }
      }, label: {
        ZStack {
          Image(systemName: "play")
            .font(.system(size: 24))
            .foregroundColor(.white)
            .padding()
          Image(systemName: "gobackward")
            .font(.system(size: 12))
            .background(Circle().fill(Color.black))
            .foregroundColor(.white)
            .padding()
            .offset(x: 5, y: 5)
        }
      }).frame(width: 50)
      Button(action: {
        submitAction(isPlaying ? .pause : .play)
      }, label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 24))
          .foregroundColor(.white)
      })
      .frame(width: 50)
      .padding()
      Button(action: {
        submitAction(.goForward(frames: 1))
      }, label: {
        Image(systemName: "forward.frame")
          .font(.system(size: 24))
          .foregroundColor(.white)
          .padding()
      }).frame(width: 50)
    }.padding(.bottom)
  }
}

struct PlaybackControls_Previews: PreviewProvider {
  static var previews: some View {
    PlaybackControls(isPlaying: true) { _ in
      
    }
  }
}
