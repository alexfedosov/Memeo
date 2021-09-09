//
//  ShareView.swift
//  Memeo
//
//  Created by Alex on 8.9.2021.
//

import SwiftUI
import Combine
import AVKit

struct ShareView: View {
  @ObservedObject var viewModel: ShareViewModel

  var body: some View {
    VStack {
      Spacer()
      VStack {
        if viewModel.isShown.wrappedValue {
          header()
          if let videoPlayer = viewModel.videoPlayer {
            VideoPlayerView(videoPlayer: videoPlayer)
              .cornerRadius(8)
              .frame(maxHeight: 400)
              .aspectRatio(viewModel.frameSize, contentMode: .fit)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.top)
          }
          buttons()
        }
      }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
        .offset(x: 0, y: viewModel.isShown.wrappedValue ? 0 : 400)
    }
      .background(Color.black.opacity(viewModel.isShown.wrappedValue ? 0.8 : 0).onTapGesture {
        viewModel.closeShareDialog()
      })
      .ignoresSafeArea(.all, edges: .vertical)
      .opacity(viewModel.isShown.wrappedValue ? 1 : 0)
  }

  @ViewBuilder
  func header() -> some View {
    HStack {
      Spacer()
      Button(action: {
        withAnimation {
          viewModel.closeShareDialog()
        }
      }, label: {
        Image(systemName: "xmark")
          .font(.system(size: 16).bold())
          .foregroundColor(Color(red: 125 / 255, green: 120 / 255, blue: 145 / 255))
          .padding(8)
          .background(Circle().fill(Color.white.opacity(0.1)))
      })
    }
    Text("Share your meme").font(.headline).padding(.bottom, 2)
    Text("Thank you for using \(Text("#memeo").bold()) hashtag!")
      .font(.system(size: 14))
      .opacity(0.6)

  }

  func buttons() -> some View {
    HStack(alignment: .lastTextBaseline) {
      Button(action: { viewModel.shareToInstagram() }, label: {
        VStack {
          Image("instagram")
            .resizable()
            .frame(width: 50, height: 50, alignment: .center)
          Text("Instagram")
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .font(.system(size: 10))
            .opacity(0.3)
            .padding(.top, 4)
        }
      }).frame(width: 60)
      if let _ = viewModel.gifURL {
        Spacer()
        Button(action: { viewModel.copyGifToPasteboard() }, label: {
          VStack {
            Image(systemName: "doc.on.doc")
              .foregroundColor(.white)
              .frame(width: 50, height: 50, alignment: .center)
              .background(Circle().fill(Color.white.opacity(0.1)))
            Text("Copy GIF")
              .multilineTextAlignment(.center)
              .foregroundColor(.white)
              .font(.system(size: 10))
              .opacity(0.3)
              .padding(.top, 4)
          }
        }).frame(width: 60)
      }
      Spacer()
      Button(action: { viewModel.saveToPhotoLibrary() }, label: {
        VStack {
          Image(systemName: "square.and.arrow.down")
            .foregroundColor(.white)
            .frame(width: 50, height: 50, alignment: .center)
            .background(Circle().fill(Color.white.opacity(0.1)))
          Text("Save video")
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .font(.system(size: 10))
            .opacity(0.3)
            .padding(.top, 4)
        }
      }).frame(width: 60)
      Spacer()
      Button(action: { viewModel.showMoreSharingOptions() }, label: {
        VStack {
          Image(systemName: "ellipsis")
            .foregroundColor(.white)
            .frame(width: 50, height: 50, alignment: .center)
            .background(Circle().fill(Color.white.opacity(0.1)))
          Text("More")
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .font(.system(size: 10))
            .opacity(0.3)
            .padding(.top, 4)
        }
      }).frame(width: 60)
    }
      .padding(.vertical)
      .padding(.top)
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}

struct ShareView_Previews: PreviewProvider {
  static let url = Bundle.main.url(forResource: "previewAsset", withExtension: "mp4")!

  static var previews: some View {
    ShareView(viewModel: ShareViewModel(isShown: .constant(true),
      videoUrl: url,
      gifURL: nil,
      frameSize: CGSize(width: 800, height: 8000),
      muted: true))
      .previewDevice("iPhone 12 mini")
  }
}
