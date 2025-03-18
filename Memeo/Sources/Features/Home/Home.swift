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
import RevenueCat
import RevenueCatUI

struct Home: View {
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
    @State var displayPaywall = false
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
                if !hasSubscription {
                    VStack(alignment: .leading) {
                        Text("Unlock templates search, extra GIF categories, sharing and more")
                            .font(.subheadline)
                            .bold()
                        Button {
                            displayPaywall = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "wand.and.stars")
                                Text("Try")
                                Text("Memeo Pro").fontWeight(.heavy)
                                Spacer()
                            }
                            .padding(8)
                            .background()
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 6, height: 6)))
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(GradientFactory.primaryGradient())
                            )
                        }
                        .tint(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                    .background(.thickMaterial)
                    .padding(.horizontal, 8)
                }
                GiphySelectorView(
                    hasSubscription: hasSubscription,
                    searchQuery: $searchQuery,
                    displayPaywall: $displayPaywall,
                    onSelectMedia: { media in
                        guard let media = media else { return }
                        Task {
                            await viewModel.create(from: .giphy(media), viewModelFactory: coordinator?.createVideoEditorViewModel)
                        }
                    }
                )
                .padding(.horizontal, 8)
                .padding(.top, 8)
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
            Task {
                let customerInfo = try? await Purchases.shared.customerInfo()
                hasSubscription = !(customerInfo?.activeSubscriptions.isEmpty ?? true)
            }

            guard let appVersion = UIApplication.appVersion else { return }
            if lastVersionPromptedForReview != appVersion {
                presentReview()
                lastVersionPromptedForReview = appVersion
            }
        })
        .sheet(isPresented: $displayPaywall) {
            PaywallView(displayCloseButton: true)
                .onRestoreCompleted({ _ in
                    hasSubscription = true
                })
                .onPurchaseCompleted { _ in
                    hasSubscription = true
                }
        }
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
            MemeoButton.standard(
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
                        case .image(let image): await viewModel.create(from: .image(image), viewModelFactory: coordinator?.createVideoEditorViewModel)
                        case .videoUrl(let url): await viewModel.create(from: .url(url), viewModelFactory: coordinator?.createVideoEditorViewModel)
                        }
                    }
                }))
            }
        }.frame(height: 44).padding(8)
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
            VideoEditor(onClose: {
                viewModel.setVideoEditorViewModel(nil)
            })
            .environmentObject(model) // Use environment injection
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
