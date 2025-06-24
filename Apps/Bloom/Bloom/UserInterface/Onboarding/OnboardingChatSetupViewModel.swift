//
//  OnboardingChatSetupViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-24.
//

import SwiftUI

@Observable @MainActor
final class OnboardingChatSetupViewModel {
  var cellModels = [ChatCellModel]()
  var error: Error?

  init() {
    setupObservers()
  }

  private var cellModelsTask: Task<Void, Never>?
  private var errorTask: Task<Void, Never>?
}

extension OnboardingChatSetupViewModel {

  func sendChatSetupContextMessage() async throws {
    try await ChatController.shared.sendSystemContextMessage(
      dummyAssistantMessage: "Let me set up some goals for you",
      systemContext: """
      You are helping the user set up the app in onboarding.
      
      You should query health data about the user, and decide on some goals to set for them. When you respond, return those goals as in-line content.
      """
    )
  }
}

private extension OnboardingChatSetupViewModel {

  func setupObservers() {
    cellModelsTask = Task.detached { [weak self] in
      for await cellModels in await ChatHistoryModifier.shared.$cellModels {
        await MainActor.run { [weak self] in
          self?.cellModels = cellModels
        }
      }
    }
    errorTask = Task.detached { [weak self] in
      for await error in await ChatController.shared.$error {
        await MainActor.run { [weak self] in
          self?.error = error
        }
      }
    }
  }
}
