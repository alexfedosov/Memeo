//
//  EditorDocument.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import AVFoundation
import UIKit

struct Document {
  var duration: CFTimeInterval
  var numberOfKeyframes: Int
  var trackers: [Tracker]
  var frameSize: CGSize
  
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

extension Document: Codable {}

extension Document {
  static func loadPreviewDocument() -> Document {
    let url = Bundle.main.url(forResource: "PreviewData", withExtension: "json")!
    let contents = try! JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    return contents
  }
}
