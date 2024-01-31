//
//  UIApplication.swift
//  Memeo
//
//  Created by Alex on 7.1.2024.
//

import Foundation
import UIKit

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
