//
//  UserID.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import Foundation
import TelemetryDeck
import BloomModel

enum UserID {
  static var value: String {
    if let value = UserDefaults.group.string(forKey: "UserID") {
      TelemetryDeck.updateDefaultUserID(to: value)
      return value
    }
    let newValue = UUID().uuidString
    UserDefaults.group.set(newValue, forKey: "UserID")
    TelemetryDeck.updateDefaultUserID(to: newValue)
    return newValue
  }
}
