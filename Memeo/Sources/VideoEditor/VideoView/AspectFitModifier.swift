//
//  AspectFitModifier.swift
//  Memer
//
//  Created by Alex on 18.8.2021.
//

import AVFoundation
import SwiftUI

struct AspectFit: ViewModifier {
    let aspectRatio: CGSize

    func body(content: Content) -> some View {
        GeometryReader(content: { reader in
            frame(content: content, parent: reader.frame(in: .local))
                .frame(width: reader.size.width, alignment: .center)
        })
    }

    func frame(content: Content, parent: CGRect) -> some View {
        if aspectRatio == .zero {
            return content.frame(width: 0, height: 0)
        }
        let rect = AVMakeRect(aspectRatio: aspectRatio, insideRect: parent)
        return content.frame(width: rect.width, height: rect.height)
    }
}
