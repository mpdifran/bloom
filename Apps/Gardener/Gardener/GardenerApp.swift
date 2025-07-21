//
//  GardenerApp.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI
import Bugsnag

@main
struct GardenerApp: App {

  init() {
    Bugsnag.start()

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

    WindowGroup(id: .WindowGroup.createNewFoodItem) {
      CreateNewFoodItemView()
    }
   
    Settings {
      PreferencesView()
    }
  }
}


extension String {
  enum WindowGroup {
    static let createNewFoodItem = "WindowGroupID.CreateNewFoodItem"
  }
}
