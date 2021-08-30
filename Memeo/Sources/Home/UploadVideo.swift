//
//  UploadVideo.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI

struct UploadVideoView: View {
  @State private var showVideoPicker = false
  @Binding var mediaURL: URL?
  
  var body: some View {
    VStack {
      Image("upload-video-icon")
      Text("UPLOAD VIDEO")
        .font(.system(size: 16, weight: .bold, design: .default))
        .foregroundColor(Color.white)
        .padding(EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0))
      Text("Upload video to create new meme template")
        .multilineTextAlignment(.center)
        .foregroundColor(.white.opacity(0.5))
      GradientBorderButton(text: "Open Gallery", action: {
        withAnimation {
          showVideoPicker = true
        }
      })
      .padding(.top, 32)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .sheet(isPresented: $showVideoPicker) {
      VideoPicker(isShown: $showVideoPicker, mediaURL: $mediaURL)
    }
  }
}

struct GradientBorderButton: View {
  let text: String
  let action: () -> ()
  
  let gradient = Gradient(colors: [
    Color(red: 247 / 255, green: 181 / 255, blue: 0),
    Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
    Color(red: 50 / 255, green: 197 / 255, blue: 1)
  ])
  
  var body: some View {
    Button(action: action, label: {
      Text(text)
        .foregroundColor(.white)
        .font(Font.system(size: 14, weight: .bold))
        .padding(EdgeInsets(top: 16, leading: 48, bottom: 16, trailing: 48))
        .cornerRadius(30)
        .background(
          Rectangle()
            .fill(LinearGradient(gradient: gradient,
                                 startPoint: .bottomLeading,
                                 endPoint: .topTrailing))
            .clipShape(RoundedRectangle(cornerRadius: .infinity))
            .overlay(
              RoundedRectangle(cornerRadius: .infinity)
                .fill(Color.black)
                .padding(1)
            )
        )
    })
  }
}

struct UploadVideoView_Previews: PreviewProvider {
  static var previews: some View {
    UploadVideoView(mediaURL: .constant(nil))
  }
}
