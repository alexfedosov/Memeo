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

enum DocumentServiceError: Error, LocalizedError {
    case unexpectedError
    case error(String)
    case fileSystemError(Error)
    case fileNotFound(URL)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unexpectedError:
            return "An unexpected error occurred"
        case .error(let message):
            return message
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .fileNotFound(let url):
            return "File not found at: \(url.path)"
        case .invalidData:
            return "The file contains invalid data"
        }
    }
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
        do {
            let url = try await VideoExporter().export(image: image)
            return try await create(fromMedia: url, copyToDocumentsDir: true)
        } catch {
            throw DocumentServiceError.unexpectedError
        }
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

    /// Cleans up temporary files in the documents directory
    /// Only deletes files with temp_ prefix or in the Temporary subdirectory
    /// Also deletes files older than 24 hours with specific temp extensions
    func cleanDocumentsDirectory() {
        let fileManager = FileManager.default
        let documentURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let tempExtensions = ["mp4", "gif", "jpeg", "png", "mov"]
        let twentyFourHoursAgo = Date().addingTimeInterval(-86400) // 24 hours ago
        
        for documentURL in documentURLs {
            // Create a dedicated temp directory if it doesn't exist yet
            let tempDirURL = documentURL.appendingPathComponent("Temporary", isDirectory: true)
            if !fileManager.fileExists(atPath: tempDirURL.path) {
                try? fileManager.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
            }
            
            do {
                // Get all files in the documents directory
                let fileURLs = try fileManager.contentsOfDirectory(
                    at: documentURL,
                    includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                    options: .skipsHiddenFiles
                )
                
                for fileURL in fileURLs {
                    // Check if it's a directory
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    
                    if isDirectory {
                        // If it's the Temporary directory, clean everything inside it
                        if fileURL.lastPathComponent == "Temporary" {
                            let tempFiles = try fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
                            for tempFile in tempFiles {
                                try? fileManager.removeItem(at: tempFile)
                            }
                        }
                    } else {
                        // For regular files, check if they are temporary files
                        let fileName = fileURL.lastPathComponent
                        let fileExtension = fileURL.pathExtension.lowercased()
                        
                        // Check if it's a temp file based on prefix
                        if fileName.hasPrefix("temp_") || fileName.hasPrefix("giphy-") {
                            try? fileManager.removeItem(at: fileURL)
                            continue
                        }
                        
                        // Check if it's a UUID-looking filename (likely temporary)
                        if fileName.count >= 36 && fileName.contains("-") && tempExtensions.contains(fileExtension) {
                            // Check if it's more than 24 hours old
                            if let creationDate = try fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                               creationDate < twentyFourHoursAgo {
                                try? fileManager.removeItem(at: fileURL)
                            }
                        }
                    }
                }
            } catch {
                print("Error cleaning documents directory: \(error)")
            }
        }
    }
    
    /// Asynchronous version of cleanDocumentsDirectory
    /// Runs in a background task to avoid blocking the main thread
    func cleanDocumentsDirectoryAsync() async {
        await Task.detached(priority: .background) {
            self.cleanDocumentsDirectory()
        }.value
    }
}
