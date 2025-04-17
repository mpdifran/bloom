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
}

public extension UserDefaults {
  static let group: UserDefaults = UserDefaults(suiteName: .groupSuiteName)!
  static let legacyGroup: UserDefaults = UserDefaults(suiteName: "group.supplements")!
}
