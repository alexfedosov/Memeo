//
// Created by Alex on 7.8.2021.
//

import Foundation
import UIKit
import AVFoundation

protocol MediaPlayerDelegate: AnyObject {
  func mediaPlayerDidPlayToTime(time: CMTime, duration: CMTime)
  func mediaPlayerDidPlayToEnd()
}

class VideoPlayer: AVPlayer {
  var layer: AVPlayerLayer! = nil
  var shouldAutoRepeat = false
  weak var delegate: MediaPlayerDelegate?
  
  var isPlaying: Bool {
    get {
      rate > 0
    }
  }
  
  private var timeObserverToken: Any?
  
  override init() {
    super.init()
    layer = AVPlayerLayer(player: self)
    layer.videoGravity = .resizeAspect
    let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    timeObserverToken = addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
      guard let duration = self?.currentItem?.duration,
            let delegate = self?.delegate else {
        return
      }
      let convertedTime = CMTimeConvertScale(time, timescale: duration.timescale, method: .default)
      delegate.mediaPlayerDidPlayToTime(time: convertedTime, duration: duration)
    }
    NotificationCenter.default.addObserver(self, selector: #selector(videoPlayerDidPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
  }
  
  deinit {
    if let token = timeObserverToken {
      removeTimeObserver(token)
    }
    
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func videoPlayerDidPlayToEnd() {
    DispatchQueue.main.async {
      self.delegate?.mediaPlayerDidPlayToEnd()
      if self.shouldAutoRepeat {
        self.seek(to: .zero)
      }
    }
  }
  
  func unload() {
    pause()
    replaceCurrentItem(with: nil)
    layer.removeFromSuperlayer()
  }
  
  func seek(to percent: Float) {
    guard let duration = currentItem?.duration else {
      return
    }
    
    let time = CMTime(value: Int64(Double(duration.value) * Double(percent)), timescale: duration.timescale)
    if time.isNumeric && time.isValid && !time.isIndefinite {
      seek(to: time)
    }
  }
  
  func seek(to frame: Int, fps: Int) {
    guard let duration = currentItem?.duration else {
      return
    }
    
    let time = CMTime(value: CMTimeValue(Int(duration.timescale) / fps * frame), timescale: duration.timescale)
    if time.isNumeric && time.isValid && !time.isIndefinite {
      seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
  }
  
}
