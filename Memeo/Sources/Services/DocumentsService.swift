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
  static let mediaFileName = "media"
  
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
  
  func load(url: URL) -> Future<(Document, AVAsset), Error> {
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
        let doc = try jsonDecoder.decode(Document.self, from: jsonData)
        let asset = AVAsset(url: url.appendingPathComponent(assetFileName))
        promise(.success((doc, asset)))
      } catch {
        promise(.failure(CocoaError(.fileReadCorruptFile)))
      }
    }
  }
  
  func save(document: Document, assetURL: URL) -> Future<URL, Error> {
    Future {[fileWrappers] promise in
      guard let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
              .first?
              .appendingPathComponent(UUID().uuidString)
              .appendingPathExtension("memeo") else {
        promise(.failure(DocumentServiceError.error("failed to resolve document directory path")))
        return
      }
      do {
        let wrappers = try fileWrappers(document, assetURL)
        try wrappers.write(to: exportURL, options: .atomic, originalContentsURL: nil)
      } catch {
        promise(.failure(error))
      }
    }
  }
  
  func fileWrappers(for document: Document, assetURL: URL) throws -> FileWrapper {
    let mainDirectory = FileWrapper(directoryWithFileWrappers: [:])
    let documentData = try JSONEncoder().encode(document)
    let documentFile = FileWrapper(regularFileWithContents: documentData)
    documentFile.preferredFilename = Self.dataFileName
    mainDirectory.addFileWrapper(documentFile)
    
    let mediaData = try Data(contentsOf: assetURL)
    let mediaFile = FileWrapper(regularFileWithContents: mediaData)
    mediaFile.preferredFilename = Self.mediaFileName
    mainDirectory.addFileWrapper(mediaFile)
    
    return mainDirectory
  }
}

extension UTType {
  static var memeoFileContentType: UTType {
    UTType(importedAs: "app.memeo.memeo")
  }
}

