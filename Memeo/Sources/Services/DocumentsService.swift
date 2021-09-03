//
//  DocumentCreatorService.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import UIKit
import AVFoundation
import Combine

enum DocumentServiceError: Error {
  case unexpectedError
  case error(String)
}

class DocumentsService {
  static let dataFileName = "data"
  static let mediaFileName = "media.mp4"
  static let pathExtention = "memeo"
  
  static var writableContentTypes: [UTType] {
    [.memeoFileContentType]
  }
  
  static var readableContentTypes: [UTType] {
    [.memeoFileContentType]
  }
  
  func create(from mediaUrl: URL) -> Future<Document, Error> {
    Future { promise in
      let asset = AVAsset(url: mediaUrl)
      
      guard let videoTrack = asset.tracks(withMediaType: .video).first else {
        promise(.failure(DocumentServiceError.unexpectedError))
        return
      }
      
      let frameSize = videoTrack.frameSize()
      asset.loadValuesAsynchronously(forKeys: ["duration"]) {
        DispatchQueue.main.async {
          let duration = asset.duration.seconds
          let numberOfKeyframes = Int(asset.duration.convertScale(Int32(Document.defaultFPS), method: .default).value)
          let document = Document(duration: duration,
                                  numberOfKeyframes: numberOfKeyframes,
                                  trackers: [],
                                  frameSize: frameSize,
                                  mediaURL: mediaUrl)
          promise(.success(document))
        }
      }
    }
  }
  
  func load(url: URL) -> Future<Document, Error> {
    Future { promise in
      do {
        let wrapper = try FileWrapper(url: url, options: .immediate)
        guard let wrappers = wrapper.fileWrappers,
              let dataFile = wrappers[Self.dataFileName],
              let jsonData = dataFile.regularFileContents,
              let assetFileName = wrappers[Self.mediaFileName]?.filename else {
          promise(.failure(CocoaError(.fileReadCorruptFile)))
          return
        }
        let jsonDecoder = JSONDecoder()
        var doc = try jsonDecoder.decode(Document.self, from: jsonData)
        doc.mediaURL = url.appendingPathComponent(assetFileName)
        promise(.success(doc))
      } catch {
        promise(.failure(CocoaError(.fileReadCorruptFile)))
      }
    }
  }
  
  func save(document: Document) -> Future<URL, Error> {
    Future {[fileWrappers] promise in
      guard let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
              .first?
              .appendingPathComponent(document.uuid.uuidString)
              .appendingPathExtension(Self.pathExtention) else {
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
    
    return mainDirectory
  }
  
  func importDocument(url: URL) -> AnyPublisher<Document, Error> {
    load(url: url)
      .flatMap {[save] in save($0 )}
      .flatMap{ [load] in load($0)}
      .eraseToAnyPublisher()
  }
  
  func listStoredTemplates() -> AnyPublisher<[Document], Never> {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return Just([]).eraseToAnyPublisher()
    }
    
    do {
      let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
      let templates = directoryContents.filter{ $0.pathExtension == "memeo" }
      return Publishers
        .MergeMany(templates.map { load(url: $0 ).map { $0 }.replaceError(with: nil) } )
        .compactMap { $0 }
        .collect()
        .eraseToAnyPublisher()
    } catch {
      return Just([]).eraseToAnyPublisher()
    }
  }
}

extension UTType {
  static var memeoFileContentType: UTType {
    UTType(importedAs: "app.memeo.memeo")
  }
}

