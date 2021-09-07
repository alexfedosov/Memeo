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
  
  var body: some View {
    NavigationView {
      VStack {
        navigationBar()
        if viewModel.templates.count == 0 {
          emptyView()
        } else {
          templateList()
        }
        NavigationLink(
          "",
          destination: editorView(),
          isActive: $viewModel.showVideoEditor)
      }.navigationBarHidden(true)
    }
    .navigationViewStyle(StackNavigationViewStyle())
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
    .onChange(of: openUrl, perform: { url in
      if let url = url {
        viewModel.importTemplate(url: url)
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
    }.frame(height: 44).padding()
  }
  
  func emptyView() -> some View {
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
  }
  
  func templateList() -> some View {
    TemplateList(templates: viewModel.templates) { viewModel.openTemplate(uuid:$0)}
      .onAppear() {
        viewModel.discoverTemplates()
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
  }
}
