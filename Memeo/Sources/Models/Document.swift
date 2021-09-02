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

struct Document {
  static let defaultFPS = 10
  
  var duration: CFTimeInterval
  var numberOfKeyframes: Int
  var trackers: [Tracker]
  var frameSize: CGSize
  var version: Int = 1
  var fps: Int = 10

  
  private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    var assetOrientation = UIImage.Orientation.up
    var isPortrait = false
    if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
      assetOrientation = .right
      isPortrait = true
    } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
      assetOrientation = .left
      isPortrait = true
    } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
      assetOrientation = .up
    } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
      assetOrientation = .down
    }
    
    return (assetOrientation, isPortrait)
  }
  
}

extension Document: Codable {
}

extension Document {
  static func loadPreviewDocument() -> Document {
    let url = Bundle.main.url(forResource: "PreviewData", withExtension: "json")!
    let contents = try! JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    return contents
  }
}

extension UTType {
    static var memeoFileContentType: UTType {
        UTType(importedAs: "app.memeo.memeo")
    }
}

extension Document {
  static let dataFileName = "data"
  static let mediaFileName = "media"
  
  static var writableContentTypes: [UTType] {
    [.memeoFileContentType]
  }
  
  static var readableContentTypes: [UTType] {
    [.memeoFileContentType]
  }
  
  init(url: URL) throws {
    let wrapper = try FileWrapper(url: url, options: .immediate)
    guard let wrappers = wrapper.fileWrappers,
          let dataFile = wrappers[Document.dataFileName],
          let jsonData = dataFile.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let jsonDecoder = JSONDecoder()
    let doc = try jsonDecoder.decode(Self.self, from: jsonData)
    self.init(duration: doc.duration,
              numberOfKeyframes: doc.numberOfKeyframes,
              trackers: doc.trackers,
              frameSize: doc.frameSize)
  }
  
  static func load(url: URL) throws -> (Document, AVAsset) {
    let wrapper = try FileWrapper(url: url, options: .immediate)
    guard let wrappers = wrapper.fileWrappers,
          let dataFile = wrappers[Document.dataFileName],
          let jsonData = dataFile.regularFileContents,
          let assetFileName = wrappers[Document.mediaFileName]?.filename else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let jsonDecoder = JSONDecoder()
    let doc = try jsonDecoder.decode(Self.self, from: jsonData)
    let asset = AVAsset(url: url.appendingPathComponent(assetFileName))
    return (doc, asset)
  }
  
  func fileWrappers(with assetURL: URL) throws -> FileWrapper {
    let mainDirectory = FileWrapper(directoryWithFileWrappers: [:])
    let documentData = try JSONEncoder().encode(self)
    let documentFile = FileWrapper(regularFileWithContents: documentData)
    documentFile.preferredFilename = Document.dataFileName
    mainDirectory.addFileWrapper(documentFile)
    
    let mediaData = try Data(contentsOf: assetURL)
    let mediaFile = FileWrapper(regularFileWithContents: mediaData)
    mediaFile.preferredFilename = Document.mediaFileName
    mainDirectory.addFileWrapper(mediaFile)
    
    return mainDirectory
  }
}
