//
//  VideoEditorHeaderView.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import SwiftUI

struct VideoEditorHeaderView: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button(
                action: {
                    viewModel.cleanDocumentsDirectory()
                    onClose()
                },
                label: {
                    ZStack {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                    }
                })
            Spacer()
            Button(
                action: {
                    viewModel.setIsPlaying(false)
                    withAnimation {
                        viewModel.setShowHelp(true)
                    }
                },
                label: {
                    Image(systemName: "questionmark")
                        .font(Font.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(EdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12))
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(7)
                })
            MemeoButton.standard(
                text: String(localized: "Share!"),
                action: {
                    Task {
                        try? await viewModel.share()
                    }
                }
            ).padding(.trailing)
        }
    }
}

struct VideoEditorHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VideoEditorHeaderView(
            viewModel: VideoEditorViewModel.preview, 
            onClose: {}
        )
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}