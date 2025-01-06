//
//  UserControllerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-06.
//

import SwiftUI
import BloomModel

@MainActor @Observable
final class UserControllerViewModel {
  var isAuthenticated: Bool = false
  var userID: UserIdentifier?
  var authToken: AuthToken?

  init() {
    observeData()
  }

  private var tasks = [Task<Void, Never>]()
}

private extension UserControllerViewModel {

  func observeData() {
    tasks.removeAll(keepingCapacity: true)

    tasks.append(Task.detached {
      for await authState in await UserController.shared.$isAuthenticated {
        let userID = await UserController.shared.authenticatedUserIdentifier
        let authToken = await UserController.shared.authToken
        await MainActor.run {
          self.isAuthenticated = authState
          self.userID = userID
          self.authToken = authToken
        }
      }
    })
  }
}
