//
//  EditorDocument.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

struct Document: Codable {
  static let defaultFPS = 10
  
  var duration: CFTimeInterval
  var numberOfKeyframes: Int
  var trackers: [Tracker]
  var frameSize: CGSize
  var mediaURL: URL
  var version: Int = 1
  var fps: Int = 10
}

extension Document {
  static func loadPreviewDocument() -> Document {
    let url = Bundle.main.url(forResource: "previewAsset", withExtension: "mp4")!
    return Document(duration: 12.8,
                    numberOfKeyframes: Int(12.8) * defaultFPS,
                    trackers: [
                      Tracker(id: UUID(),
                              text: "Test tracker",
                              position: Animation<CGPoint>(id: UUID(), keyframes: [0: CGPoint(x: 0.5, y: 0.5)], key: "position"))
                    ],
                    frameSize: CGSize(width: 1280, height: 720),
                    mediaURL: url,
                    version: 1,
                    fps: defaultFPS)
  }
}
