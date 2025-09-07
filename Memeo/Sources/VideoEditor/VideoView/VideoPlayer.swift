//
// Created by Alex on 7.8.2021.
//

import AVFoundation
import Combine
import Foundation
import UIKit

protocol MediaPlayerDelegate: AnyObject {
    func mediaPlayerDidPlayToTime(time: CMTime, duration: CMTime)
    func mediaPlayerDidPlayToEnd()
}

class VideoPlayer: AVPlayer {
    var shouldAutoRepeat = false
    weak var delegate: MediaPlayerDelegate?
    var didPlayerToEndCancellable: AnyCancellable?

    var isPlaying: Bool {
        rate > 0
    }

    private var timeObserverToken: Any?

    override init() {
        super.init()
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
            guard let duration = self?.currentItem?.duration,
                let delegate = self?.delegate
            else {
                return
            }
            let convertedTime = CMTimeConvertScale(time, timescale: duration.timescale, method: .default)
            delegate.mediaPlayerDidPlayToTime(time: convertedTime, duration: duration)
        }
    }

    deinit {
        if let token = timeObserverToken {
            removeTimeObserver(token)
        }
    }

    override func replaceCurrentItem(with item: AVPlayerItem?) {
        super.replaceCurrentItem(with: item)
        didPlayerToEndCancellable?.cancel()
        didPlayerToEndCancellable = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime, object: nil
        )
        .map {
            $0.object as? AVPlayerItem
        }
        .filter { [weak self] in
            $0 === self?.currentItem && $0 != nil
        }
        .subscribe(on: RunLoop.main)
        .sink { [weak self] notification in
            guard let self = self else {
                return
            }
            self.delegate?.mediaPlayerDidPlayToEnd()
            if self.shouldAutoRepeat {
                self.seek(to: .zero)
                self.play()
            }
        }
    }

    func unload() {
        pause()
        replaceCurrentItem(with: nil)
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
