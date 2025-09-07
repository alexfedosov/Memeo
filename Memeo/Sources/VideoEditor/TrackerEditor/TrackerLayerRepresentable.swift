//
//  TrackerLayer.swift
//  Memeo
//
//  Created by Alex on 29.8.2021.
//

import Foundation
import SwiftUI
import UIKit

protocol CALayerRepresentable {
    associatedtype CALayerType: CALayer
    func makeCALayer() -> Self.CALayerType
    func updateCALayer(_ layer: Self.CALayerType)
    static func dismantleCALayer(_ layer: Self.CALayerType)
}

class TrackerLayer: CALayer {
    let textLabel = UILabel()
    let touchAreaAround: CGFloat = 20

    override init() {
        super.init()
        masksToBounds = true

        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.font = .boldSystemFont(ofSize: 14)
        textLabel.shadowColor = UIColor.black.withAlphaComponent(0.5)
        textLabel.shadowOffset = CGSize(width: 0, height: 1)
        textLabel.layer.cornerRadius = 8
        textLabel.layer.masksToBounds = true

        addSublayer(textLabel.layer)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        textLabel.frame =
            bounds
            .insetBy(
                dx: touchAreaAround - textLabel.font.pointSize / 2,
                dy: touchAreaAround - textLabel.font.pointSize / 2)
    }

    func sizeToFit() {
        textLabel.sizeToFit()
        frame = CGRect(
            origin: CGPoint(
                x: frame.midX - textLabel.layer.frame.width / 2 - touchAreaAround,
                y: frame.midY - textLabel.layer.frame.height / 2 - touchAreaAround),
            size: CGSize(
                width: textLabel.bounds.width + touchAreaAround * 2,
                height: textLabel.bounds.height + touchAreaAround * 2))
    }
}

struct TrackerLayerRepresentable: CALayerRepresentable {
    var tracker: Tracker
    var isSelected: Bool

    func makeCALayer() -> TrackerLayer {
        TrackerLayer()
    }

    func updateCALayer(_ layer: TrackerLayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.textLabel.text = tracker.uiText
        if isSelected {
            layer.borderWidth = 2
            layer.cornerRadius = 4
            layer.borderColor = UIColor.systemYellow.cgColor
        } else {
            layer.backgroundColor = UIColor.clear.cgColor
            layer.borderColor = UIColor.clear.cgColor
        }

        layer.textLabel.backgroundColor = tracker.style.backgroundColor()
        layer.textLabel.textColor = tracker.style.foregroundColor()
        layer.textLabel.shadowColor =
            tracker.style == TrackerStyle.transparent ? UIColor.black.withAlphaComponent(0.5) : .clear
        layer.textLabel.font = .boldSystemFont(ofSize: CGFloat(tracker.size.rawValue))

        layer.sizeToFit()
        CATransaction.commit()
    }

    static func dismantleCALayer(_ layer: TrackerLayer) {
        layer.textLabel.layer.removeFromSuperlayer()
    }
}
