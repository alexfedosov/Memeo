//
//  VideoExporter.swift
//  Memeo
//
//  Created by Alex on 31.8.2021.
//

import AVKit
import Combine
import Foundation
import Photos
import ffmpegkit

enum VideoExporterError: Error {
    case unexpectedError(String)
    case albumCreatingError
}

class VideoExporter {
    let albumName = "Memeo"

    func exportGif(url: URL, trim: Bool = true) -> URL? {
        let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "meme.gif")
        let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
        var command = trim ? "-ss 0.1 -t 3" : ""
        command.append(
            " -i \(url.path)  -filter_complex \"[0:v] fps=12,scale=w=480:h=-1,split [a][b];[a] palettegen [p];[b][p] paletteuse\" -loop -1 \(outfileURL.path)"
        )
        let _ = FFmpegKit.execute(command)
        return FileManager().fileExists(atPath: outfileURL.path) ? outfileURL : nil
    }

    func export(image: UIImage) -> URL? {
        let data = image.pngData() ?? image.jpegData(compressionQuality: 1)
        let format = image.pngData() != nil ? ".png" : ".jpeg"

        guard let data = data else { return nil }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, format))
        guard let _ = try? data.write(to: url) else { return nil }

        let width = image.size.width
        let height = image.size.height
        let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, ".mp4")
        let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
        let command = " -framerate 30 -i \(url.path) -t 1 -pix_fmt yuv420p -vf \"scale=\(width):\(height),loop=-1:1\" -movflags faststart \(outfileURL.path)"
        let _ = FFmpegKit.execute(command)
        return FileManager().fileExists(atPath: outfileURL.path) ? outfileURL : nil
    }

    func export(document: Document) async throws -> URL {
        guard let assetUrl = document.mediaURL else {
            throw VideoExporterError.unexpectedError("No video tracks found")
        }

        let asset = AVAsset(url: assetUrl)
        let composition = AVMutableComposition()
        guard
            let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoExporterError.unexpectedError("No video tracks found")
        }

        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)

        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        for audioTrack in try await asset.loadTracks(withMediaType: .audio) {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
        }

        compositionVideoTrack.preferredTransform = try await videoTrack.load(.preferredTransform)
        var videoSize: CGSize = try await videoTrack.frameSize()
        let videoTrackScaling = max(640 / videoSize.width, 1)
        videoSize = CGSize(width: videoSize.width * videoTrackScaling, height: videoSize.height * videoTrackScaling)
        let frameRect = CGRect(origin: .zero, size: videoSize)

        let scaling = await frameRect.width / UIScreen.main.bounds.width

        let videoLayer = CALayer()
        videoLayer.frame = frameRect

        let outputLayer = CALayer()
        outputLayer.frame = frameRect
        outputLayer.addSublayer(videoLayer)

        let view = await TrackersEditorUIView(frame: frameRect)
        await view.updateTrackers(
            newTrackers: document.trackers, numberOfKeyframes: document.numberOfKeyframes, isPlaying: true,
            duration: composition.duration.seconds, selectedTrackerIndex: nil)

        if let sublayers = await view.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
                layer.shouldRasterize = true
                layer.rasterizationScale = await UIScreen.main.scale
                layer.isGeometryFlipped = true
                layer.add(
                    self.makeLayerScalingAnimation(scaleFactor: scaling, duration: composition.duration.seconds),
                    forKey: "scale")
                outputLayer.addSublayer(layer)
            }

        }
        outputLayer.isGeometryFlipped = true
        await outputLayer.addSublayer(view.layer)

        if let image = UIImage(named: "watermark") {
            let watermark = CALayer()
            let aspect: CGFloat = image.size.width / image.size.height
            watermark.contents = image.cgImage
            watermark.contentsGravity = .resizeAspect
            let width = frameRect.width / 6
            let height = width / aspect
            let padding = height / 2
            watermark.frame = CGRect(origin: CGPoint(x: frameRect.width - width - padding,
                                                     y: frameRect.height - height - padding),
                                     size: CGSize(width: width, height: height))
            outputLayer.addSublayer(watermark)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderScale = 1.0
        videoComposition.renderSize = frameRect.size
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer, in: outputLayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        let finalTransform = compositionVideoTrack.preferredTransform.scaledBy(x: videoTrackScaling, y: videoTrackScaling)
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]

        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        else {
            throw VideoExporterError.unexpectedError("Cannot create export session")
        }

        let videoName = "memeo-meme"
        var exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mp4")

        if FileManager().fileExists(atPath: exportURL.path) {
            do {
                try FileManager().removeItem(at: exportURL)
                print("file removed")
            } catch {
                exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")
                print("saving under generated url")
            }
        }

        export.videoComposition = videoComposition
        export.outputFileType = .mp4
        export.outputURL = exportURL

        await export.export()
        return exportURL
    }

    func makeLayerScalingAnimation(scaleFactor: CGFloat, duration: CFTimeInterval) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.duration = duration
        animation.values = [scaleFactor, scaleFactor]
        animation.keyTimes = [0, NSNumber(value: duration)]
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.speed = 1
        return animation
    }

    func createMemeoAlbum() -> Future<PHAssetCollection, Error> {
        Future { [albumName] promise in
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges(
                {
                    let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                        withTitle: albumName)
                    placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
                },
                completionHandler: { created, error in
                    if let error = error {
                        promise(.failure(error as Error))
                        return
                    }
                    if created,
                       let collectionFetchResult = placeholder.map({
                           PHAssetCollection.fetchAssetCollections(
                            withLocalIdentifiers: [$0.localIdentifier], options: nil)
                       }),
                       let album = collectionFetchResult.firstObject
                    {
                        promise(.success(album))
                    } else {
                        promise(.failure(VideoExporterError.albumCreatingError as Error))
                    }
                })
        }
    }

    func fetchMemeoAlbum() -> Future<PHAssetCollection?, Never> {
        Future { [albumName] promise in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collections = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: fetchOptions)
            promise(.success(collections.firstObject))
        }
    }

    func findOrCreateMemeoAlbum() -> AnyPublisher<PHAssetCollection, Error> {
        fetchMemeoAlbum()
            .flatMap { [createMemeoAlbum] (album) -> Future<PHAssetCollection, Error> in
                if let album = album {
                    return Future<PHAssetCollection, Error> {
                        $0(.success(album))
                    }
                } else {
                    return createMemeoAlbum()
                }
            }.eraseToAnyPublisher()
    }

    func moveAssetToMemeoAlbum(url: URL) -> AnyPublisher<String?, Error> {
        let requestPermissions = Future<Bool, Error> { promise in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    promise(.success(true))
                } else {
                    promise(.failure(VideoExporterError.unexpectedError("Permissions not granted") as Error))
                }
            }
        }.eraseToAnyPublisher()

        let moveToAlbum = findOrCreateMemeoAlbum().flatMap { album in
            Future<String?, Error> { promise in
                PHPhotoLibrary.shared().performChanges {
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    let changeRequest = PHAssetCollectionChangeRequest(for: album)
                    changeRequest?.addAssets(
                        assetRequest?.placeholderForCreatedAsset.map {
                            [$0] as NSArray
                        } ?? [])
                } completionHandler: { success, error in
                    if let error = error {
                        promise(.failure(error as Error))
                    } else {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                        promise(.success(fetchResult.firstObject?.localIdentifier))
                    }
                }
            }
        }.eraseToAnyPublisher()

        return requestPermissions.flatMap { _ in
            moveToAlbum
        }.eraseToAnyPublisher()
    }
}
