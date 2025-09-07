//
//  Home.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//  Moved to Features/Home structure
//

import AVKit
import StoreKit
import SwiftUI

struct Home: View {
    private let logger = Logger.shared
    @Binding var openUrl: URL?
    @State private var showVideoPicker = false
    @Environment(\.requestReview) private var requestReview
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""

    @ObservedObject var viewModel: HomeViewModel
    var coordinator: AppCoordinator?
    
    @State var index: Int = 0
    @State var isDragging: Bool = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var normalizedOffset: CGFloat = 0

    @State private var searchQuery: String = ""

    @State private var showSettings: Bool = false
    @State var hasSubscription = true
    
    init(openUrl: Binding<URL?>, viewModel: HomeViewModel, coordinator: AppCoordinator? = nil) {
        self._openUrl = openUrl
        self.viewModel = viewModel
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack {
            VStack {
                navigationBar()
                searchGIPHYView().padding([.horizontal, .top], 8)
            }
            .navigationDestination(isPresented: Binding(
                get: { viewModel.isImportingVideo },
                set: { _ in } // We don't need to set it from here
            )) {
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
                viewModel.setVideoEditorViewModel($0 ? viewModel.videoEditorViewModel : nil)
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
                    logger.logUserInteraction("Tap settings gear", details: nil)
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
            MemeoButton.standard(
                text: String(localized: "Create new"),
                action: {
                    logger.logUserInteraction("Tap Create new", details: nil)
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
                        case .image(let image): 
                            logger.logUserInteraction("Select image from picker", details: nil)
                            await viewModel.create(from: .image(image), viewModelFactory: coordinator?.createVideoEditorViewModel)
                        case .videoUrl(let url): 
                            logger.logUserInteraction("Select video from picker", details: ["filename": url.lastPathComponent])
                            await viewModel.create(from: .url(url), viewModelFactory: coordinator?.createVideoEditorViewModel)
                        }
                    }
                }))
            }
        }.frame(height: 44).padding(8)
    }

    @ViewBuilder
    func searchGIPHYView() -> some View {
        VStack {
            // Search is now free for all users
                TextField(String(localized: "Search"), text: $searchQuery)
                    .font(.subheadline.bold())
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            ScrollView(.horizontal) {
                HStack {
                    ForEach(["trending", "cats", "dogs", "bad day", "monday", "morning", "coffee", "workout", "music", "movie", "news", "waiting", "bro"], id: \.self) { q in
                        Button {
                            logger.logUserInteraction("Tap search category", details: ["category": q])
                            searchQuery = q == "trending" ? "" : q
                        } label: {
                            Text(q)
                            .font(.system(size: 14))
                            .padding(8)
                            .tint(.white)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }.padding(.bottom, 8)
            }
            GiphyView(searchQuery: $searchQuery, selectedMedia: .init(get: { nil }, set: { media in
                guard let media = media else { return }
                logger.logUserInteraction("Select GIPHY media", details: ["media_id": media.id])
                Task {
                    await viewModel.create(from: .giphy(media), viewModelFactory: coordinator?.createVideoEditorViewModel)
                }
            }))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .bottom)
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
            VideoEditor(viewModel: model) {
                viewModel.setVideoEditorViewModel(nil)
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
        let factory = AppViewModelFactory()
        let coordinator = AppCoordinator(viewModelFactory: factory)
        
        Home(openUrl: .constant(nil), viewModel: coordinator.homeViewModel, coordinator: coordinator)
    }
}
