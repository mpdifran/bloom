//
//  GardenerApp.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

@main
struct GardenerApp: App {

  init() {
    Task {
      do {
        try await UserController.shared.verifyAuthentication()
      } catch {
        print(error)
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }

    WindowGroup(id: GardenerAppWindowGroupID.createNewFoodItem.rawValue) {
      CreateNewFoodItemView()
    }
   
    Settings {
      PreferencesView()
    }
  }
}

enum GardenerAppWindowGroupID: String {
  case createNewFoodItem
}
