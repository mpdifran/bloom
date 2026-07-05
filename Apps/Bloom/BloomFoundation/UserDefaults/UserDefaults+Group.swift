//
//  UserDefaults+Group.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-06-01.
//

import Foundation

public extension String {
  static var groupSuiteName: String {
      guard let suiteName = Bundle.main.object(forInfoDictionaryKey: "BLOOM_APP_GROUP_ID") as? String else {
          fatalError("BLOOM_APP_GROUP_ID is not set in Info.plist")
      }
      return suiteName
  }

  /// The App Group identifier without the leading "group." prefix.
  /// Used to build Valet `SharedGroupIdentifier`s that match the App Group entitlement.
  static var groupIdentifier: String {
      let prefix = "group."
      guard groupSuiteName.hasPrefix(prefix) else { return groupSuiteName }
      return String(groupSuiteName.dropFirst(prefix.count))
  }
}

public extension UserDefaults {
  static let group: UserDefaults = UserDefaults(suiteName: .groupSuiteName)!
  static let legacyGroup: UserDefaults = UserDefaults(suiteName: "group.supplements")!
}
