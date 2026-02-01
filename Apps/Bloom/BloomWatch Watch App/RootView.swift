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
//      .onAppear {
//        guard !hasInitialized else { return }
//        hasInitialized = true
//
//        Task { @MainActor in
//          let tabs: [Tab] = [.today, .workouts, .bioAge]
//
//          for tab in tabs {
//            withTransaction(Transaction(animation: nil)) {
//              selectedTab = tab
//            }
//            // Give SwiftUI a chance to render/layout this selection
//            await Task.yield()
//            // On watchOS, a second yield often helps more than a sleep.
//            await Task.yield()
//          }
//        }
//      }
      .onOpenURL { url in
        guard url.scheme == "bloom" else { return }
        // Reconstruct path: bloom://watch/workouts -> /watch/workouts
        let path = "/\(url.host ?? "")\(url.path)"
        if path == "/watch/workouts" {
          NavigationResetController.shared.reset()
          selectedTab = .workouts
        } else if path == "/watch/bioage/details" {
          NavigationResetController.shared.reset()
          NavigationResetController.shared.shouldShowBioAgeDetails = true
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
