//
//  EditorDocument.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation

struct Document: Codable {
  var duration: CFTimeInterval
  var numberOfKeyframes: Int
  var trackers: [Tracker]
}

extension Document {
  static func loadPreviewDocument() -> Document {
    let url = Bundle.main.url(forResource: "PreviewData", withExtension: "json")!
    let contents = try! JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    return contents
  }
}
