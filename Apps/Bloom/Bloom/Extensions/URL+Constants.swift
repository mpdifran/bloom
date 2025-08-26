//
//  URL+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import Foundation

// MARK: - Feature Requests

extension URL {
    static func featureRequests(userID: String, name: String, isDark: Bool) -> URL {
        let urlString = "https://bloom.features.vote/board?api_key=cdd99333-2201-4b4a-8132-0b9d3f1c950a&is_embed=true&user_id=\(userID)&user_name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
        return URL(string: urlString)!
    }
}

// MARK: - Legal

extension URL {
  static let privacyPolicy = URL(string: "https://www.trybloom.app/privacy")!
  static let termsOfService = URL(string: "https://www.trybloom.app/tos")!
}

// MARK: - Email

extension URL {
  static let emailBloom = URL(string: "mailto:hello@trybloom.app")!
  static func emailBloom(subject: String) -> URL {
    var components = URLComponents(string: "mailto:hello@trybloom.app")!
    components.queryItems = [URLQueryItem(name: "subject", value: subject)]
    return components.url!
  }
}

// MARK: - Apple

extension URL {
  static let appleWeatherAttribution = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
  static let trackSleepWithAppleWatch = URL(string: "https://support.apple.com/en-ca/guide/watch/apd830528336/watchos")!
  static let cycleTrackingWithAppleWatch = URL(string: "https://support.apple.com/en-us/120356")!
}
