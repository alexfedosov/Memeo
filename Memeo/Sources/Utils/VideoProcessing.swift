//
//  VideoProcessing.swift
//  Memeo
//
//  Created on 18.3.2025.
//

import AVFoundation
import UIKit

/// Utility functions for video processing tasks
enum VideoProcessing {
    
    /// Generates a thumbnail from a video at a specified time
    /// - Parameters:
    ///   - url: URL of the video file
    ///   - time: Time position to extract the thumbnail (in seconds)
    ///   - size: Optional size to scale the thumbnail to
    /// - Returns: UIImage thumbnail or nil if generation fails
    static func generateThumbnail(from url: URL, at time: Double, size: CGSize? = nil) async throws -> UIImage {
        let asset = AVAsset(url: url)
        
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        // Set the maximum dimensions if a size is provided
        if let size = size {
            assetImgGenerate.maximumSize = size
        }
        
        // Specify the exact time we want
        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let imageRef = try await assetImgGenerate.image(at: cmTime).image
        
        return UIImage(cgImage: imageRef)
    }
    
    /// Extracts multiple frames from a video at regular intervals
    /// - Parameters:
    ///   - url: URL of the video file
    ///   - count: Number of frames to extract
    ///   - size: Optional size to scale the frames to
    /// - Returns: Array of UIImage frames
    static func extractFrames(from url: URL, count: Int, size: CGSize? = nil) async throws -> [UIImage] {
        let asset = AVAsset(url: url)
        
        // Get the duration of the video
        let durationSeconds = try await asset.load(.duration).seconds
        let step = durationSeconds / Double(count)
        
        var frames: [UIImage] = []
        
        // Generate thumbnails at regular intervals
        for i in 0..<count {
            let timeInSeconds = step * Double(i)
            let frame = try await generateThumbnail(from: url, at: timeInSeconds, size: size)
            frames.append(frame)
        }
        
        return frames
    }
    
    /// Gets the dimensions of a video
    /// - Parameter url: URL of the video file
    /// - Returns: CGSize containing the video dimensions
    static func getVideoDimensions(from url: URL) async throws -> CGSize {
        let asset = AVAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let track = tracks.first else {
            throw VideoProcessingError.noVideoTrack
        }
        
        let size = try await track.load(.naturalSize)
        let preferredTransform = try await track.load(.preferredTransform)
        
        // Apply the transform to get the correct dimensions
        let transformedSize = size.applying(preferredTransform)
        return CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
    }
    
    /// Gets the duration of a video
    /// - Parameter url: URL of the video file
    /// - Returns: Duration in seconds
    static func getVideoDuration(from url: URL) async throws -> Double {
        let asset = AVAsset(url: url)
        return try await asset.load(.duration).seconds
    }
}

/// Errors that can occur during video processing
enum VideoProcessingError: Error {
    case noVideoTrack
    case thumbnailGenerationFailed
    case invalidTimecode
}

// Extensions for better error descriptions
extension VideoProcessingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "The video file does not contain a valid video track"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail from video"
        case .invalidTimecode:
            return "The provided timecode is invalid for this video"
        }
    }
}