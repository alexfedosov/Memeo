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

    func exportGif(url: URL, trim: Bool = true) async throws -> URL {
        let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "meme.gif")
        let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
        var command = trim ? "-ss 0.1 -t 3" : ""
        command.append(
            " -i \(url.path)  -filter_complex \"[0:v] fps=12,scale=w=480:h=-1,split [a][b];[a] palettegen [p];[b][p] paletteuse\" -loop -1 \(outfileURL.path)"
        )
        
        let session = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FFmpegSession, Error>) in
            FFmpegKit.executeAsync(command) { session in
                if let session = session {
                    continuation.resume(returning: session)
                } else {
                    continuation.resume(throwing: VideoExporterError.unexpectedError("Failed to start FFmpeg session"))
                }
            }
        }
        
        let returnCode = session.getReturnCode()
        guard let code = returnCode, code.isValueSuccess() else {
            throw VideoExporterError.unexpectedError("Failed to export GIF: \(String(describing: session.getOutput()))")
        }
        
        guard FileManager.default.fileExists(atPath: outfileURL.path) else {
            throw VideoExporterError.unexpectedError("GIF file was not created")
        }
        
        return outfileURL
    }

    func export(image: UIImage) async throws -> URL {
        let data = image.pngData() ?? image.jpegData(compressionQuality: 1)
        let format = image.pngData() != nil ? ".png" : ".jpeg"

        guard let data = data else { 
            throw VideoExporterError.unexpectedError("Failed to convert image to data")
        }
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, format))
        
        do {
            try data.write(to: url)
        } catch {
            throw VideoExporterError.unexpectedError("Failed to write image data: \(error.localizedDescription)")
        }

        let width = image.size.width
        let height = image.size.height
        let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, ".mp4")
        let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
        let command = " -framerate 30 -i \(url.path) -t 1 -pix_fmt yuv420p -vf \"scale=\(width):\(height),loop=-1:1\" -movflags faststart \(outfileURL.path)"
        
        // Clean up the temporary image file
        defer {
            try? FileManager.default.removeItem(at: url)
        }
        
        let session = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FFmpegSession, Error>) in
            FFmpegKit.executeAsync(command) { session in
                if let session = session {
                    continuation.resume(returning: session)
                } else {
                    continuation.resume(throwing: VideoExporterError.unexpectedError("Failed to start FFmpeg session"))
                }
            }
        }
        
        let returnCode = session.getReturnCode()
        guard let code = returnCode, code.isValueSuccess() else {
            throw VideoExporterError.unexpectedError("Failed to convert image to video: \(String(describing: session.getOutput()))")
        }
        
        guard FileManager.default.fileExists(atPath: outfileURL.path) else {
            throw VideoExporterError.unexpectedError("Video file was not created")
        }
        
        return outfileURL
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

    func createMemeoAlbum() async throws -> PHAssetCollection {
        let albumName = self.albumName
        var placeholder: PHObjectPlaceholder?
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                    withTitle: albumName)
                placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { created, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if created {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: VideoExporterError.albumCreatingError)
                }
            })
        }
        
        guard let placeholderIdentifier = placeholder?.localIdentifier else {
            throw VideoExporterError.albumCreatingError
        }
        
        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [placeholderIdentifier], 
            options: nil
        )
        
        guard let album = collectionFetchResult.firstObject else {
            throw VideoExporterError.albumCreatingError
        }
        
        return album
    }

    func fetchMemeoAlbum() async -> PHAssetCollection? {
        let albumName = self.albumName
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: fetchOptions)
        
        return collections.firstObject
    }

    func findOrCreateMemeoAlbum() async throws -> PHAssetCollection {
        if let existingAlbum = await fetchMemeoAlbum() {
            return existingAlbum
        } else {
            return try await createMemeoAlbum()
        }
    }

    func moveAssetToMemeoAlbum(url: URL) async throws -> String? {
        // Request permissions first
        let authorizationStatus = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
        
        guard authorizationStatus == .authorized else {
            throw VideoExporterError.unexpectedError("Permissions not granted")
        }
        
        // Find or create the album
        let album = try await findOrCreateMemeoAlbum()
        
        // Add asset to album
        var assetIdentifier: String?
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                let changeRequest = PHAssetCollectionChangeRequest(for: album)
                
                guard let placeholder = assetRequest?.placeholderForCreatedAsset else {
                    return
                }
                
                changeRequest?.addAssets([placeholder] as NSArray)
            } completionHandler: { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Fetch the newly created asset
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        return fetchResult.firstObject?.localIdentifier
    }
}
