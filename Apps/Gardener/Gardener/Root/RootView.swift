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

  var body: some View {
    NavigationSplitView {
      SidebarView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 300)
    } content: {
      Text("Content")
    } detail: {
      Text("Detail")
    }
    .sheet($presentedSheet)
    .onAppear {
      if !userControllerViewModel.isAuthenticated {
        presentedSheet = LoginView().asAny
      }
    }
  }
}

#Preview {
  RootView()
}
