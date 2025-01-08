//
//  URL+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import Foundation

extension URL {
    static func featureRequests(userID: String, name: String, isDark: Bool) -> URL {
        let urlString = "https://bloom.features.vote/board?api_key=cdd99333-2201-4b4a-8132-0b9d3f1c950a&is_embed=true&user_id=\(userID)&user_name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))"
        return URL(string: urlString)!
    }
}

extension URL {
  static let privacyPolicy = URL(string: "https://www.trybloom.app/privacy")!
  static let termsOfService = URL(string: "https://www.trybloom.app/tos")!
}
