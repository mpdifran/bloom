//
//  UserDefaults+Group.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-06-01.
//

import Foundation

public extension String {
  static let groupSuiteName: String = "group.com.lotus-labs.bloom"
}

public extension UserDefaults {
  static let group: UserDefaults = UserDefaults(suiteName: .groupSuiteName)!
  static let legacyGroup: UserDefaults = UserDefaults(suiteName: "group.supplements")!
}
