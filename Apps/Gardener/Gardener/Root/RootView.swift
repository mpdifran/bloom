//
//  RootView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI
import AppUI

struct RootView: View {

  @State private var userControllerViewModel = UserControllerViewModel()
  @State private var presentedSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationSplitView {
      SidebarView()
        .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: 400)
    } content: {
      Text("Content")
    } detail: {
      Text("Detail")
    }
    .sheet($presentedSheet)
    .onChange(of: userControllerViewModel.isAuthenticated) { _, _ in
      if !userControllerViewModel.isAuthenticated {
        presentedSheet = LoginView().asAny
      }
    }
    .task {
      let isAuthenticated = await UserController.shared.isAuthenticated
      if !isAuthenticated {
        await MainActor.run {
          presentedSheet = LoginView().asAny
        }
      }
    }
  }
}

#Preview {
  RootView()
}
