//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI

@main
struct MemeoApp: App {
  @State var openUrl: URL?
  
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
