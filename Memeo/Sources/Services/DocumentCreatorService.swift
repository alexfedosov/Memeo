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

enum DocumentCreatorServiceError: Error {
  case unexpectedError
}

class DocumentCreatorService {
  func createDocument(from mediaUrl: URL) -> Future<(Document, AVAsset), Error> {
    Future { promise in
      let asset = AVAsset(url: mediaUrl)
      
      guard let videoTrack = asset.tracks(withMediaType: .video).first else {
        promise(.failure(DocumentCreatorServiceError.unexpectedError))
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
                                  frameSize: frameSize)
          promise(.success((document, asset)))
        }
      }
    }
  }
}
