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
  
  @StateObject var viewModel = HomeViewModel()
  
  @State var index: Int = 0
  @State var isDragging: Bool = false
  @GestureState private var dragOffset: CGFloat = 0
  @State private var offset: CGFloat = 0
  @State private var normalizedOffset: CGFloat = 0
  
  @State private var searchQuery: String = ""
  
  func animatedValueForTab(_ index: Int) -> Double {
    let offset: CGFloat = -normalizedOffset
    let diff = max(offset, CGFloat(index)) - min(offset, CGFloat(index))
    return Double(min(1, max(0.5, 1 - diff)))
  }
  
  var body: some View {
    NavigationView {
      VStack {
        navigationBar()
        searchGIPHYView().padding([.horizontal, .top], 8)
        NavigationLink(
          "",
          destination: editorView(),
          isActive: $viewModel.showVideoEditor)
      }.navigationBarHidden(true)
    }
    .navigationViewStyle(StackNavigationViewStyle())
    .presentAppTrackingRequestView(isPresented: $viewModel.isShowingAppTrackingDialog)
    .fullScreenCover(isPresented: $showVideoPicker) {
      VideoPicker(isShown: $showVideoPicker, mediaURL: $viewModel.selectedAssetUrl)
    }
    .fullScreenCover(isPresented: $viewModel.isImportingVideo, content: {
      ZStack {
        VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
          .ignoresSafeArea()
        HStack {
          Text("Importing your video").font(.title3)
          ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
        }.padding()
      }
    })
  }
  
  @ViewBuilder
  func navigationBar() -> some View {
    HStack {
      Image("logo").resizable().aspectRatio(contentMode: .fit).frame(height: 28)
      Spacer()
      GradientBorderButton(text: "Create new", action: {
        withAnimation {
          showVideoPicker = true
        }
      })
    }.frame(height: 44).padding(8)
  }
  
  @ViewBuilder
  func searchGIPHYView() -> some View {
    VStack{
      TextField("Search GIPHY", text: $searchQuery)
        .font(.subheadline.bold())
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
      GiphyView(searchQuery: $searchQuery, selectedMedia: $viewModel.selectedGIPHYMedia)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
  
  func emptyView() -> some View {
    VStack {
      Spacer()
      Text("Make your own templates!")
        .font(.headline)
        .foregroundColor(Color.white)
        .padding()
      Text("Add video from your photo library to create a new template")
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .foregroundColor(.white.opacity(0.5))
        .frame(maxWidth: 300)
      Spacer()
    }
  }
  
  func templateList() -> some View {
    TemplateList(templates: viewModel.templates) {
      viewModel.openTemplate(uuid: $0)
    }
  }
  
  @ViewBuilder
  func editorView() -> some View {
    if let model = viewModel.videoEditorViewModel {
      VideoEditor(viewModel: model) { [weak viewModel] in
        viewModel?.videoEditorViewModel = nil
      }
      .navigationBarHidden(true)
    } else {
      Text("Hello")
    }
  }
}

struct Home_Previews: PreviewProvider {
  static var previews: some View {
    Home(openUrl: .constant(nil))
    Home(openUrl: .constant(nil)).previewDevice("iPhone 12 mini")
  }
}
