//
//  Bundle+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-24.
//

import SwiftUI

extension Bundle {

  var appVersion: String? {
    guard let versionString = infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }

    if let buildString = infoDictionary?["CFBundleVersion"] as? String {
      return "\(versionString) (\(buildString))"
    }
    return versionString
  }
}
