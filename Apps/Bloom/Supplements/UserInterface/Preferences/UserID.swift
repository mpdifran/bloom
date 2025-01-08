//
//  UserID.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import Foundation
import TelemetryDeck
import RevenueCat
import BloomModel
import Valet

private extension String {
  static let userID = "UserID"
}

enum UserID {
  private static let valet = Valet.iCloudValet(
    with: Identifier(nonEmpty: "UserController")!,
    accessibility: .afterFirstUnlock
  )

  static var value: String {
    // Migrate from UserDefaults to Keychain
    if let value = UserDefaults.group.string(forKey: .userID) {
      do {
        try valet.setString(value, forKey: .userID)
        UserDefaults.group.removeObject(forKey: .userID)
      } catch {
        TelemetryDeck.errorOccurred(
          id: "UserID.value",
          category: .thrownException,
          message: error.localizedDescription
        )
      }
    }

    // This throws an error if it's not found.
    if let value = try? valet.string(forKey: .userID) {
      recordUserIDValue(value)
      return value
    }

    // Create a new ID.
    let newValue = UUID().uuidString
    do {
      try valet.setString(newValue, forKey: .userID)
    } catch {
      TelemetryDeck.errorOccurred(
        id: "UserID.value",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
    recordUserIDValue(newValue)
    return newValue
  }

  static func recordUserIDValue(_ value: String) {
    Task {
      await MainActor.run {
        TelemetryDeck.updateDefaultUserID(to: value)
        Purchases.shared.attribution.setAttributes([
          "$telemetryDeckUserId": TelemetryManager.shared.hashedDefaultUser
        ])
      }
    }
  }
}
