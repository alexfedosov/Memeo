//
//  GiphySelectorView.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import SwiftUI
import GiphyUISDK

struct GiphySelectorView: View {
    let hasSubscription: Bool
    @Binding var searchQuery: String
    @Binding var displayPaywall: Bool
    let onSelectMedia: (GPHMedia?) -> Void
    
    var body: some View {
        VStack {
            searchField()
            categoriesScrollView()
            GiphyView(searchQuery: $searchQuery, selectedMedia: .init(get: { nil }, set: { media in
                guard let media = media else { return }
                onSelectMedia(media)
            }))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
    
    @ViewBuilder
    private func searchField() -> some View {
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
    }
    
    @ViewBuilder
    private func categoriesScrollView() -> some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(["trending", "cats", "dogs", "bad day (pro)", "monday (pro)", "morning (pro)", "coffee (pro)", "workout (pro)", "music (pro)", "movie (pro)", "news (pro)", "waiting (pro)", "bro (pro)"], id: \.self) { q in
                    categoryButton(for: q)
                }
            }.padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private func categoryButton(for category: String) -> some View {
        let hasPro = category.hasSuffix(" (pro)")
        let label = hasPro ? String(category.dropLast(6)) : category
        
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
}

struct GiphySelectorView_Previews: PreviewProvider {
    static var previews: some View {
        GiphySelectorView(
            hasSubscription: true,
            searchQuery: .constant(""),
            displayPaywall: .constant(false),
            onSelectMedia: { _ in }
        )
        .preferredColorScheme(.dark)
        .background(Color.black)
    }
}