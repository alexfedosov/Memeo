//
//  VideoPicker.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import AVFoundation
import SwiftUI
import MobileCoreServices

class VideoPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isShown: Bool
    @Binding var mediaURL: URL?

    init(isShown: Binding<Bool>, mediaURL: Binding<URL?>) {
        _isShown = isShown
        _mediaURL = mediaURL
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            return
        }
        mediaURL = url
        isShown = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShown = false
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var mediaURL: URL?

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<VideoPicker>) {
    }

    func makeCoordinator() -> VideoPickerCoordinator {
        VideoPickerCoordinator(isShown: $isShown, mediaURL: $mediaURL)
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
