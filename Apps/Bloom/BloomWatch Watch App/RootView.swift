//
//  RootView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth

extension RootView {
  enum Tab {
    case today
    case bioAge
    case workouts
  }
}

struct RootView: View {

  @State private var selectedTab: RootView.Tab = .bioAge
  @State private var hasInitialized = false

  var body: some View {
    NavigationStack {
      TabView(selection: $selectedTab) {
        TodayTabView()
          .tag(Tab.today)
        BioAgeTabView()
          .tag(Tab.bioAge)
        WorkoutsTabView()
          .tag(Tab.workouts)
      }
      .tabViewStyle(.verticalPage)
      .onAppear {
        guard !hasInitialized else { return }
        hasInitialized = true

        // Force load all tabs by briefly visiting each one without animation
        withTransaction(Transaction(animation: nil)) {
          selectedTab = .today
          selectedTab = .workouts
          selectedTab = .bioAge
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    RootView()
  }
}
