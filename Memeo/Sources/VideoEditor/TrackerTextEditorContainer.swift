//
//  TrackerTextEditorContainer.swift
//  Memeo
//
//  Created by Claude on 18/03/2025.
//

import SwiftUI

struct TrackerTextEditorContainer: View {
    @ObservedObject var viewModel: VideoEditorViewModel
    
    var body: some View {
        VStack {
            if let index = viewModel.selectedTrackerIndex, viewModel.isEditingText {
                TrackerTextEditor(
                    text: viewModel.document.trackers[index].text,
                    style: viewModel.document.trackers[index].style,
                    size: viewModel.document.trackers[index].size
                ) { result in
                    viewModel.updateTrackerText(
                        text: result.text,
                        style: result.style,
                        size: result.size
                    )
                } onDeleteTracker: {
                    viewModel.setIsEditingText(false)
                    viewModel.submit(action: .removeSelectedTracker)
                }.transition(.opacity)
            }
        }
    }
}

struct TrackerTextEditorContainer_Previews: PreviewProvider {
    static var previews: some View {
        TrackerTextEditorContainer(viewModel: VideoEditorViewModel.preview)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}