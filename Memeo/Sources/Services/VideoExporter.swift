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
import VideoToolbox

enum VideoExporterError: Error {
    case unexpectedError(String)
    case albumCreatingError
    case encodingError(String)
    case hardwareAccelerationError
}

class VideoExporter {
    let albumName = "Memeo"

    func exportGif(url: URL, trim: Bool = true) async throws -> URL {
        let outfileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "meme.gif")
        let outfileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outfileName)
        var command = trim ? "-ss 0.1 -t 3" : ""
        command.append(
            " -hwaccel videotoolbox -i \(url.path) -filter_complex \"[0:v] fps=12,scale=w=480:h=-1,split [a][b];[a] palettegen [p];[b][p] paletteuse\" -loop -1 \(outfileURL.path)"
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
        let command = " -hwaccel videotoolbox -framerate 30 -i \(url.path) -t 1 -c:v h264_videotoolbox -pix_fmt yuv420p -preset fast -b:v 2M -vf \"scale=\(width):\(height),loop=-1:1\" -movflags faststart \(outfileURL.path)"
        
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

        // First try with hardware acceleration using AVAssetExportSession with highest quality settings
        let highQualityExportResult = try? await exportWithSession(composition: composition, videoComposition: videoComposition)
        if let exportURL = highQualityExportResult {
            return exportURL
        }
        
        // If the initial export failed, try again with AVAssetExportSession using medium quality
        let mediumQualityExportResult = try? await exportWithSession(composition: composition, videoComposition: videoComposition, presetName: AVAssetExportPresetMediumQuality)
        if let exportURL = mediumQualityExportResult {
            return exportURL
        }
        
        // Finally, if all else fails, try with AVAssetWriter for more control
        return try await exportWithWriter(composition: composition, videoComposition: videoComposition)        
    }
    
    private func exportWithSession(composition: AVComposition, videoComposition: AVVideoComposition, presetName: String = AVAssetExportPresetHighestQuality) async throws -> URL {
        guard let export = AVAssetExportSession(asset: composition, presetName: presetName) else {
            throw VideoExporterError.unexpectedError("Cannot create export session")
        }

        let videoName = "memeo-meme"
        var exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mp4")

        if FileManager().fileExists(atPath: exportURL.path) {
            do {
                try FileManager().removeItem(at: exportURL)
            } catch {
                exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mp4")
            }
        }

        export.videoComposition = videoComposition
        export.outputFileType = .mp4
        export.outputURL = exportURL
        
        // Add hardware acceleration options if supported
        if #available(iOS 15.0, *) {
            export.canPerformMultiplePassesOverSourceMediaData = true
        }
        
        await export.export()
        
        // Check for export success
        if export.status == .completed {
            return exportURL
        } else if let error = export.error {
            throw VideoExporterError.encodingError(error.localizedDescription)
        } else {
            throw VideoExporterError.unexpectedError("Export failed with status: \(export.status.rawValue)")
        }
    }
    
    private func exportWithWriter(composition: AVComposition, videoComposition: AVVideoComposition) async throws -> URL {
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
            
        if FileManager.default.fileExists(atPath: exportURL.path) {
            try FileManager.default.removeItem(at: exportURL)
        }
        
        // Create asset writer
        guard let writer = try? AVAssetWriter(outputURL: exportURL, fileType: .mp4) else {
            throw VideoExporterError.unexpectedError("Cannot create asset writer")
        }
        
        // Configure video settings with hardware acceleration
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoComposition.renderSize.width,
            AVVideoHeightKey: videoComposition.renderSize.height,
            AVVideoCompressionPropertiesKey: [
                "ProfileLevel": "H264High",
                "RealTime": true,
                "Quality": 0.7,
                "ExpectedFrameRate": 30
            ]
        ]
        
        // Add video input
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        videoInput.expectsMediaDataInRealTime = false
        videoInput.transform = CGAffineTransform(scaleX: 1, y: 1) // Adjust if needed
        
        // Add audio input if available
        let audioTracks = try await composition.loadTracks(withMediaType: .audio)
        var audioInput: AVAssetWriterInput? = nil
        
        if !audioTracks.isEmpty {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = false
            
            if let audioInput = audioInput, writer.canAdd(audioInput) {
                writer.add(audioInput)
            }
        }
        
        // Add video input to writer
        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        } else {
            throw VideoExporterError.unexpectedError("Cannot add video input to writer")
        }
        
        // Create video compositor
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: videoComposition.renderSize.width,
            kCVPixelBufferHeightKey as String: videoComposition.renderSize.height
        ]
        
        let videoCompositionOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: try await composition.loadTracks(withMediaType: .video),
            videoSettings: pixelBufferAttributes)
        videoCompositionOutput.videoComposition = videoComposition
        
        // Create reader
        guard let reader = try? AVAssetReader(asset: composition) else {
            throw VideoExporterError.unexpectedError("Cannot create asset reader")
        }
        
        if reader.canAdd(videoCompositionOutput) {
            reader.add(videoCompositionOutput)
        } else {
            throw VideoExporterError.unexpectedError("Cannot add video output to reader")
        }
        
        // Add audio output if available
        var audioOutput: AVAssetReaderTrackOutput? = nil
        if !audioTracks.isEmpty, let audioTrack = audioTracks.first {
            audioOutput = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
            
            if let audioOutput = audioOutput, reader.canAdd(audioOutput) {
                reader.add(audioOutput)
            }
        }
        
        // Start writing
        guard reader.startReading(), writer.startWriting() else {
            throw VideoExporterError.unexpectedError("Failed to start reading/writing")
        }
        
        writer.startSession(atSourceTime: .zero)
        
        // Process video
        let videoProcessingTask = Task {
            while true {
                if !videoInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000) // Wait 10ms before checking again
                    continue
                }
                
                guard let sampleBuffer = videoCompositionOutput.copyNextSampleBuffer() else {
                    videoInput.markAsFinished()
                    break
                }
                
                if !videoInput.append(sampleBuffer) {
                    break
                }
            }
        }
        
        // Process audio if available
        let audioProcessingTask = Task {
            guard let audioInput = audioInput, let audioOutput = audioOutput else { return }
            
            while true {
                if !audioInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000) // Wait 10ms before checking again
                    continue
                }
                
                guard let sampleBuffer = audioOutput.copyNextSampleBuffer() else {
                    audioInput.markAsFinished()
                    break
                }
                
                if !audioInput.append(sampleBuffer) {
                    break
                }
            }
        }
        
        // Wait for processing to complete
        await videoProcessingTask.value
        if audioInput != nil {
            await audioProcessingTask.value
        }
        
        // Finish writing
        return try await withCheckedThrowingContinuation { continuation in
            writer.finishWriting {
                if writer.status == .completed {
                    continuation.resume(returning: exportURL)
                } else if let error = writer.error {
                    continuation.resume(throwing: VideoExporterError.encodingError(error.localizedDescription))
                } else {
                    continuation.resume(throwing: VideoExporterError.unexpectedError("Unknown error during export"))
                }
            }
        }
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
