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

enum VideoExporterError: Error, LocalizedError {
    case unexpectedError(String)
    case albumCreatingError
    case encodingError(String)
    case hardwareAccelerationError
    case fileSystemError(Error)
    case assetCreationError
    case permissionDenied
    case fileNotFound(URL)
    case tempDirectoryAccessFailed
    
    var errorDescription: String? {
        switch self {
        case .unexpectedError(let message):
            return "An unexpected error occurred: \(message)"
        case .albumCreatingError:
            return "Failed to create photo album"
        case .encodingError(let message):
            return "Video encoding failed: \(message)"
        case .hardwareAccelerationError:
            return "Hardware acceleration is not available for this device"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .assetCreationError:
            return "Failed to create video asset"
        case .permissionDenied:
            return "Permission to access Photos library was denied"
        case .fileNotFound(let url):
            return "File not found at: \(url.path)"
        case .tempDirectoryAccessFailed:
            return "Failed to access temporary directory"
        }
    }
}

/// A resource handle class that implements the AutoCloseable pattern to ensure proper cleanup
class ResourceHandle<T> {
    private let resource: T
    private let cleanup: (T) -> Void
    
    init(resource: T, cleanup: @escaping (T) -> Void) {
        self.resource = resource
        self.cleanup = cleanup
    }
    
    func get() -> T {
        return resource
    }
    
    deinit {
        cleanup(resource)
    }
}

class VideoExporter {
    let albumName = "Memeo"
    
    // A utility function to create a temporary URL with given extension
    private func createTemporaryURL(withExtension fileExtension: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = ProcessInfo.processInfo.globallyUniqueString
        let url = tempDir.appendingPathComponent(filename).appendingPathExtension(fileExtension)
        
        return url
    }

    func exportGif(url: URL, trim: Bool = true) async throws -> URL {
        // Validate input first
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VideoExporterError.fileNotFound(url)
        }
        
        // Create a temporary output URL
        let outfileURL: URL
        do {
            outfileURL = try createTemporaryURL(withExtension: "gif")
        } catch {
            throw VideoExporterError.tempDirectoryAccessFailed
        }
        
        // Create a resource handle to ensure cleanup if anything fails
        let resourceHandle = ResourceHandle(resource: outfileURL) { url in
            // Only try to delete the file if something went wrong and it exists
            if Thread.current.isCancelled, FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // Create FFmpeg command
        var command = trim ? "-ss 0.1 -t 3" : ""
        command.append(
            " -hwaccel videotoolbox -i \(url.path) -filter_complex \"[0:v] fps=12,scale=w=480:h=-1,split [a][b];[a] palettegen [p];[b][p] paletteuse\" -loop -1 \(outfileURL.path)"
        )
        
        do {
            let session = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FFmpegSession, Error>) in
                FFmpegKit.executeAsync(command) { session in
                    if let session = session {
                        continuation.resume(returning: session)
                    } else {
                        continuation.resume(throwing: VideoExporterError.unexpectedError("Failed to start FFmpeg session"))
                    }
                }
            }
            
            // Check the FFmpeg execution result
            let returnCode = session.getReturnCode()
            guard let code = returnCode, code.isValueSuccess() else {
                let errorOutput = session.getOutput() ?? "No error details available"
                throw VideoExporterError.encodingError("Failed to export GIF: \(errorOutput)")
            }
            
            // Verify the output file was created
            guard FileManager.default.fileExists(atPath: outfileURL.path) else {
                throw VideoExporterError.fileNotFound(outfileURL)
            }
            
            // Return the URL of the successfully created GIF
            return resourceHandle.get()
        } catch {
            // If we get here, something went wrong, so let's clean up
            if FileManager.default.fileExists(atPath: outfileURL.path) {
                try? FileManager.default.removeItem(at: outfileURL)
            }
            
            // Propagate the original error or wrap it if needed
            if let videoError = error as? VideoExporterError {
                throw videoError
            } else {
                throw VideoExporterError.unexpectedError("Failed to export GIF: \(error.localizedDescription)")
            }
        }
    }

    func export(image: UIImage) async throws -> URL {
        // Get image data, preferring PNG format if available
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 1) else { 
            throw VideoExporterError.unexpectedError("Failed to convert image to data")
        }
        
        let format = image.pngData() != nil ? "png" : "jpeg"
        
        // Create temporary URLs for both the image and the output video
        let imageURL: URL
        let outfileURL: URL
        
        do {
            imageURL = try createTemporaryURL(withExtension: format)
            outfileURL = try createTemporaryURL(withExtension: "mp4")
        } catch {
            throw VideoExporterError.tempDirectoryAccessFailed
        }
        
        // Create a resource handle to clean up temp files when done
        let tempFileResources = ResourceHandle(resource: (imageURL, outfileURL)) { urls in
            // Clean up both temporary files
            try? FileManager.default.removeItem(at: urls.0)
            if Thread.current.isCancelled {
                try? FileManager.default.removeItem(at: urls.1)
            }
        }
        
        do {
            // Write the image data to disk
            try data.write(to: imageURL, options: .atomic)
            
            let width = image.size.width
            let height = image.size.height
            
            // Create FFmpeg command
            let command = " -hwaccel videotoolbox -framerate 30 -i \(imageURL.path) -t 1 -c:v h264_videotoolbox -pix_fmt yuv420p -preset fast -b:v 2M -vf \"scale=\(width):\(height),loop=-1:1\" -movflags faststart \(outfileURL.path)"
            
            let session = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FFmpegSession, Error>) in
                FFmpegKit.executeAsync(command) { session in
                    if let session = session {
                        continuation.resume(returning: session)
                    } else {
                        continuation.resume(throwing: VideoExporterError.unexpectedError("Failed to start FFmpeg session"))
                    }
                }
            }
            
            // Check the FFmpeg execution result
            let returnCode = session.getReturnCode()
            guard let code = returnCode, code.isValueSuccess() else {
                let errorOutput = session.getOutput() ?? "No error details available"
                throw VideoExporterError.encodingError("Failed to convert image to video: \(errorOutput)")
            }
            
            // Verify the output file was created
            guard FileManager.default.fileExists(atPath: outfileURL.path) else {
                throw VideoExporterError.fileNotFound(outfileURL)
            }
            
            // Return the URL of the successfully created video
            return tempFileResources.get().1
        } catch {
            // If we get here, something went wrong, so let's clean up the output file
            // (image file will be cleaned up by the ResourceHandle)
            if FileManager.default.fileExists(atPath: outfileURL.path) {
                try? FileManager.default.removeItem(at: outfileURL)
            }
            
            // Propagate the original error or wrap it if needed
            if let videoError = error as? VideoExporterError {
                throw videoError
            } else if let fileError = error as? CocoaError, fileError.isFileError {
                throw VideoExporterError.fileSystemError(error)
            } else {
                throw VideoExporterError.unexpectedError("Failed to export image to video: \(error.localizedDescription)")
            }
        }
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
        // Create export session
        guard let export = AVAssetExportSession(asset: composition, presetName: presetName) else {
            throw VideoExporterError.unexpectedError("Cannot create export session")
        }

        // Create a temporary output URL
        let exportURL: URL
        do {
            exportURL = try createTemporaryURL(withExtension: "mp4")
        } catch {
            throw VideoExporterError.tempDirectoryAccessFailed
        }
        
        // Create a resource handle to clean up the output file if anything fails
        let resourceHandle = ResourceHandle(resource: exportURL) { url in
            if Thread.current.isCancelled, FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // If file already exists (shouldn't happen with unique names, but just in case), remove it
        if FileManager.default.fileExists(atPath: exportURL.path) {
            do {
                try FileManager.default.removeItem(at: exportURL)
            } catch {
                throw VideoExporterError.fileSystemError(error)
            }
        }

        // Configure export session
        export.videoComposition = videoComposition
        export.outputFileType = .mp4
        export.outputURL = exportURL
        
        // Add hardware acceleration options if supported
        if #available(iOS 15.0, *) {
            export.canPerformMultiplePassesOverSourceMediaData = true
        }
        
        // Start export
        await export.export()
        
        // Check for export success
        switch export.status {
        case .completed:
            return resourceHandle.get()
            
        case .failed:
            if let error = export.error {
                throw VideoExporterError.encodingError(error.localizedDescription)
            } else {
                throw VideoExporterError.unexpectedError("Export failed with no error details")
            }
            
        case .cancelled:
            throw VideoExporterError.unexpectedError("Export was cancelled")
            
        default:
            throw VideoExporterError.unexpectedError("Export failed with status: \(export.status.rawValue)")
        }
    }
    
    private func exportWithWriter(composition: AVComposition, videoComposition: AVVideoComposition) async throws -> URL {
        // Create a temporary output URL
        let exportURL: URL
        do {
            exportURL = try createTemporaryURL(withExtension: "mp4")
        } catch {
            throw VideoExporterError.tempDirectoryAccessFailed
        }
        
        // Create a resource handle to clean up the output file if anything fails
        let resourceHandle = ResourceHandle(resource: exportURL) { url in
            if Thread.current.isCancelled, FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // Make sure the output file doesn't already exist
        if FileManager.default.fileExists(atPath: exportURL.path) {
            do {
                try FileManager.default.removeItem(at: exportURL)
            } catch {
                throw VideoExporterError.fileSystemError(error)
            }
        }
        
        // Keep track of resources that need to be cleaned up
        var reader: AVAssetReader?
        var writer: AVAssetWriter?
        var videoProcessingTask: Task<Void, Never>?
        var audioProcessingTask: Task<Void, Never>?
        
        // Make sure to clean up tasks on exit
        defer {
            videoProcessingTask?.cancel()
            audioProcessingTask?.cancel()
        }
        
        do {
            // Create asset writer
            writer = try AVAssetWriter(outputURL: exportURL, fileType: .mp4)
            
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
                
                if let audioInput = audioInput, writer!.canAdd(audioInput) {
                    writer!.add(audioInput)
                }
            }
            
            // Add video input to writer
            if writer!.canAdd(videoInput) {
                writer!.add(videoInput)
            } else {
                throw VideoExporterError.encodingError("Cannot add video input to writer")
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
            reader = try AVAssetReader(asset: composition)
            
            if reader!.canAdd(videoCompositionOutput) {
                reader!.add(videoCompositionOutput)
            } else {
                throw VideoExporterError.encodingError("Cannot add video output to reader")
            }
            
            // Add audio output if available
            var audioOutput: AVAssetReaderTrackOutput? = nil
            if !audioTracks.isEmpty, let audioTrack = audioTracks.first {
                audioOutput = AVAssetReaderTrackOutput(
                    track: audioTrack,
                    outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
                
                if let audioOutput = audioOutput, reader!.canAdd(audioOutput) {
                    reader!.add(audioOutput)
                }
            }
            
            // Start reading and writing
            guard reader!.startReading(), writer!.startWriting() else {
                throw VideoExporterError.encodingError("Failed to start reading/writing")
            }
            
            writer!.startSession(atSourceTime: .zero)
            
            // Process video
            videoProcessingTask = Task {
                while true {
                    if Task.isCancelled {
                        videoInput.markAsFinished()
                        break
                    }
                    
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
            if let audioInput = audioInput, let audioOutput = audioOutput {
                audioProcessingTask = Task {
                    while true {
                        if Task.isCancelled {
                            audioInput.markAsFinished()
                            break
                        }
                        
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
            }
            
            // Wait for processing to complete
            await videoProcessingTask!.value
            if let audioProcessingTask = audioProcessingTask {
                await audioProcessingTask.value
            }
            
            // Finish writing
            return try await withCheckedThrowingContinuation { continuation in
                writer!.finishWriting {
                    if writer!.status == .completed {
                        continuation.resume(returning: resourceHandle.get())
                    } else if let error = writer!.error {
                        continuation.resume(throwing: VideoExporterError.encodingError(error.localizedDescription))
                    } else {
                        continuation.resume(throwing: VideoExporterError.unexpectedError("Unknown error during export"))
                    }
                }
            }
        } catch {
            // Cancel any running tasks
            videoProcessingTask?.cancel()
            audioProcessingTask?.cancel()
            
            // Clean up the output file if it exists
            if FileManager.default.fileExists(atPath: exportURL.path) {
                try? FileManager.default.removeItem(at: exportURL)
            }
            
            // Propagate the error with appropriate wrapping
            if let videoError = error as? VideoExporterError {
                throw videoError
            } else if let avError = error as? AVError {
                throw VideoExporterError.encodingError("AVFoundation error: \(avError.localizedDescription)")
            } else {
                throw VideoExporterError.unexpectedError("Export failed: \(error.localizedDescription)")
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
        // Validate input URL
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VideoExporterError.fileNotFound(url)
        }
        
        // Request permissions first
        let authorizationStatus = await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
        
        // Check if permissions were granted
        guard authorizationStatus == .authorized else {
            throw VideoExporterError.permissionDenied
        }
        
        // Find or create the album
        let album: PHAssetCollection
        do {
            album = try await findOrCreateMemeoAlbum()
        } catch {
            if let videoError = error as? VideoExporterError {
                throw videoError
            } else {
                throw VideoExporterError.albumCreatingError
            }
        }
        
        // Add asset to album with better error handling
        do {
            // Create a variable to capture any asset request error
            var assetRequestError: Error?
            var placeholderIdentifier: String?
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                PHPhotoLibrary.shared().performChanges {
                    // Create asset request
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    if assetRequest == nil {
                        assetRequestError = VideoExporterError.assetCreationError
                        return
                    }
                    
                    // Get placeholder and remember its identifier
                    guard let placeholder = assetRequest?.placeholderForCreatedAsset else {
                        assetRequestError = VideoExporterError.assetCreationError
                        return
                    }
                    
                    placeholderIdentifier = placeholder.localIdentifier
                    
                    // Add to album
                    let changeRequest = PHAssetCollectionChangeRequest(for: album)
                    changeRequest?.addAssets([placeholder] as NSArray)
                } completionHandler: { success, error in
                    if let assetRequestError = assetRequestError {
                        continuation.resume(throwing: assetRequestError)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else if !success {
                        continuation.resume(throwing: VideoExporterError.assetCreationError)
                    } else {
                        continuation.resume()
                    }
                }
            }
            
            // If we have a placeholder ID, try to use it to find the asset directly
            if let placeholderIdentifier = placeholderIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [placeholderIdentifier], options: nil)
                if let asset = fetchResult.firstObject {
                    return asset.localIdentifier
                }
            }
            
            // Fallback: fetch the most recently created video asset (less reliable)
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            
            return fetchResult.firstObject?.localIdentifier
        } catch {
            // Properly categorize and wrap the error
            if let videoError = error as? VideoExporterError {
                throw videoError
            } else if let phError = error as? PHPhotosError {
                throw VideoExporterError.encodingError("Photos library error: \(phError.localizedDescription)")
            } else {
                throw VideoExporterError.unexpectedError("Failed to add video to album: \(error.localizedDescription)")
            }
        }
    }
}
