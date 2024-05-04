//
//  Home.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import AVKit
import StoreKit
import SwiftUI

struct Home: View {
    @Binding var openUrl: URL?
    @State private var showVideoPicker = false
    @Environment(\.requestReview) private var requestReview
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""

    @StateObject var viewModel = HomeViewModel()

    @State var index: Int = 0
    @State var isDragging: Bool = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var normalizedOffset: CGFloat = 0

    @State private var searchQuery: String = ""

    @State private var showSettings: Bool = false

    func animatedValueForTab(_ index: Int) -> Double {
        let offset: CGFloat = -normalizedOffset
        let diff = max(offset, CGFloat(index)) - min(offset, CGFloat(index))
        return Double(min(1, max(0.5, 1 - diff)))
    }

    var body: some View {
        NavigationStack {
            VStack {
                navigationBar()
                searchGIPHYView().padding([.horizontal, .top], 8)
            }
            .navigationDestination(isPresented: $viewModel.isImportingVideo) {
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                        .ignoresSafeArea()
                    HStack {
                        Text("Importing your video").font(.title3)
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).padding(.leading)
                    }.padding()
                }
            }
            .navigationDestination(isPresented: .init(get: {
                viewModel.videoEditorViewModel != nil
            }, set: {
                viewModel.videoEditorViewModel = $0 ? viewModel.videoEditorViewModel : nil
            })) {
                editorView()
            }
        }
        .toolbar(.hidden)
        .presentInfoView(isPresented: $showSettings)
        .onAppear(perform: {
            guard let appVersion = UIApplication.appVersion else { return }
            if lastVersionPromptedForReview != appVersion {
                presentReview()
                lastVersionPromptedForReview = appVersion
            }
        })
    }

    @ViewBuilder
    func navigationBar() -> some View {
        HStack {
            Image("logo").resizable().aspectRatio(contentMode: .fit).frame(height: 28)
            Spacer()
            Button(
                action: {
                    withAnimation {
                        showSettings = true
                    }
                },
                label: {
                    Image(systemName: "gear")
                        .font(Font.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(9)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(7)
                })
            GradientBorderButton(
                text: String(localized: "Create new"),
                action: {
                    withAnimation {
                        showVideoPicker = true
                    }
                }
            ).fullScreenCover(isPresented: $showVideoPicker) {
                VideoPicker(isShown: $showVideoPicker,
                            result: .init(get: { nil }, set: { result in
                    guard let result = result else { return }
                    Task {
                        switch result {
                        case .image(let image): try await viewModel.create(from: .image(image))
                        case .videoUrl(let url): try await viewModel.create(from: .url(url))
                        }
                    }
                }))
            }
        }.frame(height: 44).padding(8)
    }

    @ViewBuilder
    func searchGIPHYView() -> some View {
        VStack {
            TextField(String(localized: "Search GIPHY"), text: $searchQuery)
                .font(.subheadline.bold())
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
            GiphyView(searchQuery: $searchQuery, selectedMedia: .init(get: { nil }, set: { media in
                guard let media = media else { return }
                Task {
                    try await viewModel.create(from:.giphy(media))
                }
            }))
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

    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(2))
            requestReview()
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home(openUrl: .constant(nil))
        Home(openUrl: .constant(nil)).previewDevice("iPhone 12 mini")
    }
}
