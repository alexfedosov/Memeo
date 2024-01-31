//
//  HelpView.swift
//  Memeo
//
//  Created by Alex on 12.9.2021.
//

import SwiftUI
import AVKit

struct HelpView: View {
  
  private struct Slide {
    let videoFileName: String
    let title: String
    let subtitle: String
    
    var videoUrl: URL? {
      Bundle.main.url(forResource: videoFileName, withExtension: "mp4")
    }
  }
  
  @Binding var isPresented: Bool
  
  @State private var videoPlayer = VideoPlayer()
  @State private var slideIndex = 0
  @State private var slideOpacity: Double = 1
  
  private let slides = [
    Slide(videoFileName: "learn1",
          title: String(localized: "Animate position with keyframes"),
          subtitle: String(localized: "Move timeline to another frame and drag text to the desired position")),
    Slide(videoFileName: "learn2",
          title: String(localized: "Hide and show text"),
          subtitle: String(localized: "Use Hide/Show button to toggle text visibility on a specific keyframe"))
  ]
  
  private var isLastSlide: Bool {
    slideIndex == slides.count - 1
  }
  
  private var currentSlide: Slide {
    slides[slideIndex]
  }
  
  var body: some View {
    VStack {
      VStack {
        VideoPlayerView(videoPlayer: videoPlayer)
          .cornerRadius(8)
          .frame(maxHeight: 400)
          .aspectRatio(1, contentMode: .fit)
          .frame(maxWidth: .infinity, alignment: .center)
          .opacity(slideOpacity)
        Text(currentSlide.title)
          .font(.system(size: 16, weight: .black))
          .padding(.top, 8)
        Text(currentSlide.subtitle)
          .font(.system(size: 14))
          .multilineTextAlignment(.center)
          .padding(.top, 8)
        DialogGradientButton(text: isLastSlide ? String(localized: "Close") : String(localized: "One more tip"), action: {
          if isLastSlide {
            withAnimation {
              isPresented = false
            }
          } else {
            withAnimation(.easeIn(duration: 0.1)) {
              slideOpacity = 0
            }
            withAnimation(.linear(duration: 0).delay(0.1)) {
              slideIndex += 1
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.15)) {
              slideOpacity = 1
            }
          }
        })
        .padding(.top)
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .background(Color(white: 15 / 255))
      .cornerRadius(16)
      .padding()
    }
    .onChange(of: slideIndex, perform: { value in
      playVideo(for: currentSlide)
    })
    .onAppear() {
      playVideo(for: currentSlide)
    }
  }
  
  private func playVideo(for slide: Slide) {
    if let url = slide.videoUrl {
      videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))
      videoPlayer.pause()
      videoPlayer.isMuted = true
      videoPlayer.shouldAutoRepeat = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        videoPlayer.play()
      }
    }
  }
}

extension View {
  public func presentHelpView(isPresented: Binding<Bool>) -> some View {
    self.modifier(FullscreenModifier(presenting: HelpView(isPresented: isPresented), canCancelByBackgroundTap: true, isPresented: isPresented))
          .environment(\.locale, .init(identifier: "it"))
  }
}

struct HelpView_Previews: PreviewProvider {
  static var previews: some View {
    Rectangle().fill(Color.green)
      .ignoresSafeArea()
      .frame(maxHeight: .infinity)
      .presentHelpView(isPresented: .constant(true))
      .previewDevice("iPhone 12 Pro Max")

    Rectangle().fill(Color.yellow)
      .ignoresSafeArea()
      .frame(maxHeight: .infinity)
      .presentHelpView(isPresented: .constant(true))
      .previewDevice("iPhone 12 mini")
  }
}
