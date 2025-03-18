//
//  EditorDocument.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//  Moved to Models/Domain structure
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

struct Document: Codable {
    static let defaultFPS = 10

    var uuid: UUID = UUID()
    var duration: CFTimeInterval
    var numberOfKeyframes: Int
    var trackers: [Tracker]
    var frameSize: CGSize
    var mediaURL: URL?
    var previewURL: URL?
    var version: Int = 1
    var fps: Int = 10
}

extension Document: Hashable {
    // Swift can automatically synthesize hash(into:) and == for structs
    // when all properties are Hashable
}

extension Document {
    static func loadPreviewDocument() -> Document {
        let url = Bundle.main.url(forResource: "previewAsset", withExtension: "mp4")!
        return Document(
            duration: 12.8,
            numberOfKeyframes: Int(12.8) * defaultFPS,
            trackers: [
                Tracker(
                    id: UUID(),
                    text: "Test tracker",
                    style: .transparent,
                    size: .small,
                    position: Animation<CGPoint>(id: UUID(), keyframes: [0: CGPoint(x: 0.5, y: 0.5)], key: "position"),
                    fade: Animation<Bool>(id: UUID(), keyframes: [:], key: "opacity"),
                    rotation: Animation<Double>(id: UUID(), keyframes: [:], key: "rotation")
                )
            ],
            frameSize: CGSize(width: 1280, height: 720),
            mediaURL: url,
            version: 1,
            fps: defaultFPS)
    }
}
