//
//  Home.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
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
    
    @State var index: Int = 0
    @State var isDragging: Bool = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var normalizedOffset: CGFloat = 0

    @State private var searchQuery: String = ""

    @State private var showSettings: Bool = false
    @State var displayPaywall = false
    @State var hasSubscription = true
    
    init(openUrl: Binding<URL?>, viewModel: HomeViewModel = HomeViewModel()) {
        self._openUrl = openUrl
        self.viewModel = viewModel
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
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 50 / 255, green: 197 / 255, blue: 1),
                                                Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
                                                Color(red: 247 / 255, green: 181 / 255, blue: 0),
                                            ]
                                                .reversed()),
                                            startPoint: .bottomLeading,
                                            endPoint: .topTrailing))
                            )
                        }
                        .tint(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                    .background(.thickMaterial)
                    .padding(.horizontal, 8)
                }
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
                        case .image(let image): await viewModel.create(from: .image(image))
                        case .videoUrl(let url): await viewModel.create(from: .url(url))
                        }
                    }
                }))
            }
        }.frame(height: 44).padding(8)
    }

    @ViewBuilder
    func searchGIPHYView() -> some View {
        VStack {
            if hasSubscription {
                TextField(String(localized: "Search"), text: $searchQuery)
                    .font(.subheadline.bold())
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            } else {
                Button {
                    displayPaywall = true
                } label: {
                    HStack {
                        Text(String(localized: "Search"))
                        Spacer()
                        HStack {
                            Text(String(localized: "with memeo pro"))
                            Image(systemName: "lock")
                        }.font(.system(size: 12, weight: .black))
                    }
                    .font(.subheadline.bold())
                    .opacity(0.3)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                }.tint(.white)
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(["trending", "cats", "dogs", "bad day (pro)", "monday (pro)", "morning (pro)", "coffee (pro)", "workout (pro)", "music (pro)", "movie (pro)", "news (pro)", "waiting (pro)", "bro (pro)"], id: \.self) { q in
                        let hasPro = q.hasSuffix(" (pro)")
                        let label = hasPro ? String(q.dropLast(6)) : q
                        Button {
                            if hasPro && !hasSubscription {
                                displayPaywall = true
                            } else {
                                searchQuery = label == "trending" ? "" : label
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text(label)
                                if hasPro && !hasSubscription {
                                    Image(systemName: "lock")
                                }
                            }
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
                Task {
                    await viewModel.create(from: .giphy(media))
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
        Home(openUrl: .constant(nil), viewModel: HomeViewModel())
//        Home(openUrl: .constant(nil), viewModel: HomeViewModel()).previewDevice("iPhone 12 mini")
    }
}
