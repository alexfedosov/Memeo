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

    func create(fromMedia url: URL, copyToDocumentsDir: Bool = true) -> Future<Document, Error> {
        Future { promise in
            var assetUrl = url

            if copyToDocumentsDir {
                guard
                    let importURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        .first?
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(".mp4")
                else {
                    promise(.failure(DocumentServiceError.error("failed to resolve document directory path")))
                    return
                }

                do {
                    try FileManager.default.copyItem(at: url, to: importURL)
                } catch {
                    promise(.failure(DocumentServiceError.error(error.localizedDescription)))
                    return
                }
                assetUrl = importURL
            }

            let asset = AVAsset(url: assetUrl)
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                promise(.failure(DocumentServiceError.unexpectedError))
                return
            }

            let frameSize = videoTrack.frameSize()
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = asset.duration.seconds
                    let numberOfKeyframes = Int(
                        asset.duration.convertScale(Int32(Document.defaultFPS), method: .default).value)
                    let document = Document(
                        duration: duration,
                        numberOfKeyframes: numberOfKeyframes,
                        trackers: [],
                        frameSize: frameSize,
                        mediaURL: assetUrl)
                    promise(.success(document))
                }
            }
        }
    }

    func create(fromGIPHY media: GPHMedia) -> AnyPublisher<Document, Error> {
        guard
            let importURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("giphy-\(media.id)")
                .appendingPathExtension(".mp4")
        else {
            return Fail(error: DocumentServiceError.unexpectedError).eraseToAnyPublisher()
        }

        guard let urlString = media.url(rendition: .fixedWidth, fileType: .mp4),
            let url = URL(string: urlString)
        else {
            return Fail(error: DocumentServiceError.unexpectedError).eraseToAnyPublisher()
        }

        if FileManager.default.fileExists(atPath: importURL.path) {
            return create(fromMedia: importURL, copyToDocumentsDir: false).eraseToAnyPublisher()
        } else {
            return URLSession.shared
                .dataTaskPublisher(for: url)
                .tryMap { data, response in
                    try data.write(to: importURL, options: .atomic)
                }
                .flatMap { self.create(fromMedia: importURL, copyToDocumentsDir: false) }
                .eraseToAnyPublisher()
        }
    }

    func load(url: URL) -> Future<Document, Error> {
        Future { promise in
            do {
                let wrapper = try FileWrapper(url: url, options: .immediate)
                guard let wrappers = wrapper.fileWrappers,
                    let dataFile = wrappers[Self.dataFileName],
                    let jsonData = dataFile.regularFileContents,
                    let assetFileName = wrappers[Self.mediaFileName]?.filename
                else {
                    promise(.failure(CocoaError(.fileReadCorruptFile)))
                    return
                }
                let jsonDecoder = JSONDecoder()
                var doc = try jsonDecoder.decode(Document.self, from: jsonData)
                doc.mediaURL = url.appendingPathComponent(assetFileName)
                if let previewFileName = wrappers[Self.previewFileName]?.filename {
                    doc.previewURL = url.appendingPathComponent(previewFileName)
                }
                promise(.success(doc))
            } catch {
                promise(.failure(CocoaError(.fileReadCorruptFile)))
            }
        }
    }

    func save(document: Document) -> Future<URL, Error> {
        Future { [fileWrappers] promise in
            guard
                let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    .first?
                    .appendingPathComponent(document.uuid.uuidString)
                    .appendingPathExtension(Self.pathExtention)
            else {
                promise(.failure(DocumentServiceError.error("failed to resolve document directory path")))
                return
            }
            do {
                let wrappers = try fileWrappers(document)
                try wrappers.write(to: exportURL, options: .atomic, originalContentsURL: nil)
                promise(.success(exportURL))
            } catch {
                promise(.failure(error))
            }
        }
    }

    func fileWrappers(for document: Document) throws -> FileWrapper {
        guard let mediaUrl = document.mediaURL else {
            throw DocumentServiceError.unexpectedError
        }
        let mainDirectory = FileWrapper(directoryWithFileWrappers: [:])
        let documentData = try JSONEncoder().encode(document)
        let documentFile = FileWrapper(regularFileWithContents: documentData)
        documentFile.preferredFilename = Self.dataFileName
        mainDirectory.addFileWrapper(documentFile)

        let mediaData = try Data(contentsOf: mediaUrl)
        let mediaFile = FileWrapper(regularFileWithContents: mediaData)
        mediaFile.preferredFilename = Self.mediaFileName
        mainDirectory.addFileWrapper(mediaFile)

        var previewUrl = document.previewURL
        if previewUrl == nil {
            previewUrl = VideoExporter().exportGif(url: mediaUrl)
        }

        if let previewUrl = previewUrl {
            let previewData = try Data(contentsOf: previewUrl)
            let previewFile = FileWrapper(regularFileWithContents: previewData)
            previewFile.preferredFilename = Self.previewFileName
            mainDirectory.addFileWrapper(previewFile)
        }

        return mainDirectory
    }

    func importDocument(url: URL) -> AnyPublisher<Document, Error> {
        load(url: url)
            .flatMap { [save] in save($0) }
            .flatMap { [load] in load($0) }
            .eraseToAnyPublisher()
    }

    func listStoredTemplates() -> AnyPublisher<[Document], Never> {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return Just([]).eraseToAnyPublisher()
        }

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory, includingPropertiesForKeys: nil)
            let templates = directoryContents.filter { $0.pathExtension == "memeo" }.sorted { $0.path < $1.path }
            return
                Publishers
                .MergeMany(templates.map { load(url: $0).map { $0 }.replaceError(with: nil) })
                .subscribe(on: DispatchQueue.global())
                .compactMap { $0 }
                .collect()
                .eraseToAnyPublisher()
        } catch {
            return Just([]).eraseToAnyPublisher()
        }
    }

    func cleanDocumentsDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else {
            return
        }

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory, includingPropertiesForKeys: nil)
            for url in directoryContents {
                try FileManager.default.removeItem(at: url)
                print("Removed \(url)!")
            }
        } catch {
            return
        }
    }
}
