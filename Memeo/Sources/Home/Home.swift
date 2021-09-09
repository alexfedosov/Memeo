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

  func animatedValueForTab(_ index: Int) -> Double {
    let offset: CGFloat = -normalizedOffset
    let diff = max(offset, CGFloat(index)) - min(offset, CGFloat(index))
    return Double(min(1, max(0.5, 1 - diff)))
  }

  var body: some View {
    NavigationView {
      VStack {
        navigationBar()
        GeometryReader { geometry in
          VStack(alignment: .leading) {
            HStack {
              Text("Featured templates").font(.subheadline.weight(.bold))
                .opacity(animatedValueForTab(0))
                .scaleEffect(CGFloat(max(animatedValueForTab(0), 0.99)))
                .onTapGesture {
                  index = 0
                  withAnimation(.linear(duration: 0.2)) {
                    self.offset = CGFloat(index) * -geometry.size.width
                    self.normalizedOffset = offset / geometry.size.width
                  }
                }
              Text("My templates").font(.subheadline.weight(.bold))
                .opacity(animatedValueForTab(1))
                .scaleEffect(CGFloat(max(animatedValueForTab(1), 0.99)))
                .onTapGesture {
                  index = 1
                  withAnimation(.linear(duration: 0.2)) {
                    self.offset = CGFloat(index) * -geometry.size.width
                    self.normalizedOffset = offset / geometry.size.width
                  }
                }
                .padding(.leading, 8)
              Spacer()
            }
              .padding([.leading, .trailing])
            ScrollView(showsIndicators: false) {
              HStack(alignment: .center, spacing: 0) {
                emptyFeaturedTemplatesView()
                  .frame(width: geometry.size.width)
                  .frame(maxHeight: .infinity)
                  .background(Color.black)
                if viewModel.templates.count > 0 {
                  templateList()
                    .frame(width: geometry.size.width)
                    .frame(maxHeight: .infinity)
                } else {
                  emptyView()
                    .frame(width: geometry.size.width)
                    .frame(maxHeight: .infinity)
                    .background(Color.black)
                }
              }
            }
              .content
              .offset(x: offset)
              .frame(width: geometry.size.width, alignment: .leading)
              .gesture(DragGesture()
                .onChanged({ value in
                  isDragging = true
                  let translation = value.translation.width + -geometry.size.width * CGFloat(index)
                  self.offset = max(min(0, translation), -geometry.size.width)
                  self.normalizedOffset = offset / geometry.size.width
                })
                .onEnded({ value in
                  if value.predictedEndTranslation.width < geometry.size.width / 2, index < 2 - 1 {
                    self.index += 1
                  }
                  if value.predictedEndTranslation.width > geometry.size.width / 2, index > 0 {
                    self.index -= 1
                  }
                  withAnimation(.easeOut(duration: 0.2)) {
                    self.offset = CGFloat(index) * -geometry.size.width
                    self.normalizedOffset = offset / geometry.size.width
                    self.isDragging = false
                  }
                }))
          }
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
    }.frame(height: 44).padding()
  }

  func emptyFeaturedTemplatesView() -> some View {
    VStack {
      Spacer()
      Text("We don't have featured templates yet")
        .font(.headline)
        .foregroundColor(Color.white)
        .padding()
      Spacer()
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
