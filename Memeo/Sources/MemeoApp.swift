//
//  MemeoApp.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import SwiftUI

@main
struct MemeoApp: App {
  @State var templateURL: URL?
  
  var body: some Scene {
    WindowGroup {
      ZStack {
        Rectangle().fill(Color.black).ignoresSafeArea()
        Home().colorScheme(.dark)
      }.onOpenURL(perform: { url in
        templateURL = url
      })
    }
  }
}
