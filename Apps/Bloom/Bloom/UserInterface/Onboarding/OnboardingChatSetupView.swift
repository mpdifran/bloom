//
//  OnboardingChatSetupView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-24.
//

import SwiftUI
import AppUI

struct OnboardingChatSetupView: View {
  let onContinue: () -> Void

  @State private var viewModel = OnboardingChatSetupViewModel()
  @State private var scrollToBottomTrigger = false

  @State private var error: Error?

  var body: some View {
    ChatLayoutView(
      cellModels: $viewModel.cellModels,
      scrollToBottomTrigger: $scrollToBottomTrigger,
      onLoadMore: { },
      onIsAtBottomChanged: { _ in }
    )
    .alert(error: $error)
    .task {
      do {
        try await viewModel.sendChatSetupContextMessage()
      } catch {
        self.error = error
      }
    }
  }
}

#Preview {
  OnboardingChatSetupView() { }
}
