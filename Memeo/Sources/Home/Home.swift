//
//  Home.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import SwiftUI
import AVKit

struct Home: View {
  @Binding var openUrl: URL?
  @State private var showVideoPicker = false
  
  @ObservedObject var viewModel = HomeViewModel()
  
  var body: some View {
    NavigationView {
      VStack {
        HStack {
          Image("logo").resizable().aspectRatio(contentMode: .fit).frame(height: 28)
          Spacer()
          GradientBorderButton(text: "Create new", action: {
            withAnimation {
              showVideoPicker = true
            }
          })
        }.frame(height: 44).padding()
        if viewModel.templates.count == 0 {
          VStack {
            Spacer()
            Text("Create new template")
              .font(.headline)
              .foregroundColor(Color.white)
              .padding()
            Text("Open video from your photo library to create a new template")
              .font(.subheadline)
              .multilineTextAlignment(.center)
              .foregroundColor(.white.opacity(0.5))
              .frame(maxWidth: 300)
            Spacer()
          }.onAppear() {
            viewModel.discoverTemplates()
          }
        } else {
          ScrollView {
            ForEach(viewModel.templates) { preview in
              TemplatePreviewView(preview: preview).onTapGesture {
                viewModel.openTemplate(uuid: preview.id)
              }.padding(.bottom, 8)
            }.padding()
          }.onAppear() {
            viewModel.discoverTemplates()
          }
        }
        NavigationLink(
          "",
          destination: editorView(),
          isActive: $viewModel.showVideoEditor)
      }.navigationBarHidden(true)
    }
    .fullScreenCover(isPresented: $showVideoPicker) {
      VideoPicker(isShown: $showVideoPicker, mediaURL: $viewModel.selectedAssetUrl)
    }
    .fullScreenCover(isPresented: $viewModel.isImportingTemplate, content: {
      ZStack {
        VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
          .ignoresSafeArea()
        HStack {
          Text("Importing template..").font(.title3)
          ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
        }.padding()
      }
    })
    .onChange(of: openUrl, perform: { url in
      if let url = url {
        viewModel.importTemplate(url: url)
      }
    })
  }
  
  @ViewBuilder
  func editorView() -> some View {
    if let model = viewModel.videoEditorViewModel {
      VideoEditor(viewModel: model) { viewModel.videoEditorViewModel = nil}
        .navigationBarHidden(true)
    } else {
      Text("Hello")
    }
  }
}

struct TemplatePreviewView: View {
  let preview: HomeViewTemplatePreview
  @State var videoPlayer = VideoPlayer()
  
  var body: some View {
    VideoPlayerView(videoPlayer: videoPlayer)
      .aspectRatio(preview.aspectRatio, contentMode: .fill)
      .frame(maxHeight: 400, alignment: .center)
      .cornerRadius(16)
      .onAppear() {
        if videoPlayer.currentItem == nil {
          videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: preview.mediaURL))
          videoPlayer.isMuted = true
          videoPlayer.shouldAutoRepeat = true
          videoPlayer.seek(to: .zero)
        }
      }
  }
}

struct Home_Previews: PreviewProvider {
  static var previews: some View {
    Home(openUrl: .constant(nil))
  }
}
