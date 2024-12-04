//
//  RootView.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import SwiftUI

struct RootView: View {
  var body: some View {
    NavigationSplitView {
      SidebarView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 300)
    } content: {
      Text("Content")
    } detail: {
      Text("Detail")
    }
  }
}

#Preview {
  RootView()
}
