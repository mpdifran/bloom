//
//  ActionsTabView.swift
//  Bloom
//
//  Created by Claude on 2026-07-23.
//

import SwiftUI
import AppUI

/// Full-screen content for the prominent "Log" tab: the action grid plus a View Chats tile.
/// The Chat with Bud launcher lives in the global tab bar accessory (see `ChatBudAccessoryView`).
struct ActionsTabView: View {

  @State private var presentedCardSheet: AnyView?

  var body: some View {
    NavigationStack {
      BloomScrollView {
        ActionsList(
          presentedCardSheet: $presentedCardSheet,
          onDismiss: { presentedCardSheet = nil },
          layout: .grid
        )
      }
      .navigationTitle("Log")
    }
    .sheet($presentedCardSheet)
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    ActionsTabView()
  }
}
