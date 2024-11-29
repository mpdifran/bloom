//
//  UIApplication+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import UIKit

extension UIApplication {

    func openAppSettings() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            if canOpenURL(appSettingsURL) {
                open(appSettingsURL, options: [:], completionHandler: nil)
            }
        }
    }
}
