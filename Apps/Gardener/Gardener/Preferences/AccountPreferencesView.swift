//
//  AccountPreferencesView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-23.
//

import SwiftUI
import AppUI

struct AccountPreferencesView: View {
  @State private var userControllerViewModel = UserControllerViewModel()

  var body: some View {
    Form {
      detailsSection
    }
    .formStyle(.grouped)
    .tabItem {
      Label("Account", systemImage: "person.crop.circle.fill")
    }
  }
}

private extension AccountPreferencesView {

  var detailsSection: some View {
    Section("Account Details") {
      LabeledContent("State") {
        Text(userControllerViewModel.isAuthenticated ? "Signed In" : "Signed Out")
      }

      if userControllerViewModel.isAuthenticated {
        AsyncButton(role: .destructive) {
          try await UserController.shared.logout()
        } label: {
          Text("Sign Out")
            .horizontallyCentered()
        }
        .foregroundStyle(.red)
        .buttonStyle(.plain)
      }
    }
  }
}

#Preview {
  AccountPreferencesView()
}
