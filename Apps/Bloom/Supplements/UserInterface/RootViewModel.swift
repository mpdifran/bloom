//
//  RootViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-02.
//

import SwiftUI

@Observable @MainActor
final class UserControllerViewModel: Sendable {
  var isAuthenticated = true

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
        await MainActor.run {
          self.isAuthenticated = authState
        }
      }
    })
  }
}
