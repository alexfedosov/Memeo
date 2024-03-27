//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Firebase
import GiphyUISDK
import SwiftUI

@main
struct MemeoApp: App {
    @State var openUrl: URL?

    init() {
        FirebaseApp.configure()
        Giphy.configure(apiKey: "Y1yEr5cD6XeiWadQrhG7BpoQZMDmQYe8")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Rectangle().fill(Color.black).ignoresSafeArea()
                Home(openUrl: $openUrl)
            }
            .onOpenURL(perform: { url in
                openUrl = url
            })
            .colorScheme(.dark)
        }
    }
}
