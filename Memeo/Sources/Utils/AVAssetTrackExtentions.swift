//
//  AVAssetTrackExtentions.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import AVFoundation
import UIKit

extension AVAssetTrack {
  func orientation() -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    let transform = preferredTransform
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
  
  func frameSize() -> CGSize {
    if orientation().isPortrait {
      return CGSize(
        width: naturalSize.height,
        height: naturalSize.width)
    } else {
      return naturalSize
    }
  }
}
