//
//  RootView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth

struct RootView: View {

  var body: some View {
    NavigationStack {
      TabView {
        BioAgeTabView()
        WorkoutsTabView()
      }
      .tabViewStyle(.verticalPage)
    }
  }
}

#Preview {
  PreviewEnvironment {
    RootView()
  }
}
