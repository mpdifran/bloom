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
  static let subreddit = URL(string: "https://www.reddit.com/r/tryBloom")!
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

// MARK: - Citations

extension URL {
  static let adultActivityLevels = URL(string: "https://www.cdc.gov/physical-activity-basics/guidelines/adults.html")!
  static let faoHumanEnergyRequirements = URL(string: "https://www.fao.org/4/y5686e/y5686e00.htm")!
  static let dietaryGuidelinesForAmericans = URL(string: "https://www.dietaryguidelines.gov/sites/default/files/2020-12/Dietary_Guidelines_for_Americans_2020-2025.pdf")!
  static let sleepStageRanges = URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4246141/")!
  static let friendDatabase = URL(string: "https://pubmed.ncbi.nlm.nih.gov/26455884/")!
  static let bristolStoolScale = URL(string: "https://www.tandfonline.com/doi/abs/10.3109/00365529709011203")!
  static let stoolHabits = URL(string: "https://pubmed.ncbi.nlm.nih.gov/20205503/")!
  static let aceFitnessCalculators = URL(string: "https://www.acefitness.org/resources/everyone/tools-calculators/")!
}
