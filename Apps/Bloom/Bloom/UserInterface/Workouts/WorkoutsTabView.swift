//
//  WorkoutsTabView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-30.
//

import SwiftUI

struct WorkoutsTabView: View {
  var body: some View {
    NavigationStack {
      WorkoutsListView(titleDisplayMode: .large)
        .tabBar()
    }
  }
}

#Preview {
  WorkoutsTabView()
}
