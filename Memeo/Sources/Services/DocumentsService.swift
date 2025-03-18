//
//  DocumentCreatorService.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import AVFoundation
import Combine
import Foundation
import GiphyUISDK
import UIKit

enum DocumentServiceError: Error {
    case unexpectedError
    case error(String)
}

class DocumentsService {
    static let dataFileName = "data"
    static let mediaFileName = "media.mp4"
    static let previewFileName = "preview.gif"
    static let pathExtention = "memeo"

    func create(fromMedia url: URL, copyToDocumentsDir: Bool = true) async throws -> Document {
        var assetUrl = url

        if copyToDocumentsDir {
            guard
                let importURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    .first?
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(".mp4")
            else {
                throw DocumentServiceError.error("failed to resolve document directory path")
            }

            try FileManager.default.copyItem(at: url, to: importURL)
            assetUrl = importURL
        }

        let asset = AVAsset(url: assetUrl)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw DocumentServiceError.unexpectedError
        }

        let frameSize = try await videoTrack.frameSize()
        let duration = try await asset.load(.duration)
        let numberOfKeyframes = Int(duration.convertScale(Int32(Document.defaultFPS), method: .default).value)
        return Document(
            duration: duration.seconds,
            numberOfKeyframes: numberOfKeyframes,
            trackers: [],
            frameSize: frameSize,
            mediaURL: assetUrl)
    }

    func create(fromImage image: UIImage) async throws -> Document {
        guard let url = VideoExporter().export(image: image) else {
            throw DocumentServiceError.unexpectedError
        }
        return try await create(fromMedia: url, copyToDocumentsDir: true)
    }

    func create(fromGIPHY media: GPHMedia) async throws -> Document {
        guard
            let importURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("giphy-\(media.id)")
                .appendingPathExtension("mp4"),
            let urlString = media.url(rendition: .fixedWidth, fileType: .mp4),
            let url = URL(string: urlString)
        else {
            throw DocumentServiceError.unexpectedError
        }
        print(media.availableMp4Url())

        if !FileManager.default.fileExists(atPath: importURL.path) {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: importURL, options: .atomic)
        }
        return try await create(fromMedia: importURL, copyToDocumentsDir: false)
    }

    func cleanDocumentsDirectory() {
        for url in FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) {
            if let directoryContents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                for url in directoryContents {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
    }
    
    func cleanDocumentsDirectoryAsync() async {
        await Task.detached(priority: .background) {
            for url in FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) {
                if let directoryContents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                    for url in directoryContents {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            }
        }.value
    }
}
