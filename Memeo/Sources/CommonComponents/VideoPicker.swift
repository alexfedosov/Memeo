//
//  VideoPicker.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import AVFoundation
import Foundation
import MobileCoreServices
import SwiftUI

enum MediaPickerResult {
    case image(UIImage)
    case videoUrl(URL)
}

class VideoPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isShown: Bool
    @Binding var result: MediaPickerResult?

    init(isShown: Binding<Bool>, result: Binding<MediaPickerResult?>) {
        _isShown = isShown
        _result = result
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        defer {
            isShown = false
        }

        guard let identifier = info[UIImagePickerController.InfoKey.mediaType] as? String else { return }
        switch identifier {
        case UTType.image.identifier:
            let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
            guard let image = editedImage ?? originalImage else { return }
            result = .image(image)
        case UTType.movie.identifier:
            guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
            result = .videoUrl(url)
        default: print("Unsupported media type \(identifier)")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShown = false
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var result: MediaPickerResult?

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: UIViewControllerRepresentableContext<VideoPicker>
    ) {
    }

    func makeCoordinator() -> VideoPickerCoordinator {
        VideoPickerCoordinator(isShown: $isShown, result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.mediaTypes = [UTType.movie.identifier, UTType.image.identifier]
        picker.videoMaximumDuration = 60
        picker.videoQuality = .typeMedium
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
}
