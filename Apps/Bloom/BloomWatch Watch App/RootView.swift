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
  @State private var presentedActionSheet: AnyView?

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
        } else if path == "/watch/actions" {
          presentedActionSheet = ActionsView(performDismiss: {
            presentedActionSheet = nil
          }).asAny
        } else if path.hasPrefix("/watch/actions/") {
          let actionId = String(path.dropFirst("/watch/actions/".count))
          handleActionDeepLink(actionId: actionId)
        }
      }
      .sheet($presentedActionSheet)
    }
  }

  private func handleActionDeepLink(actionId: String) {
    let dismiss = { presentedActionSheet = nil }

    switch actionId {
    case "food":
      presentedActionSheet = LogFoodView(performDismiss: dismiss).asAny
    case "drink":
      presentedActionSheet = LogDrinkView(performDismiss: dismiss).asAny
    case "weight":
      presentedActionSheet = LogWeightView(performDismiss: dismiss).asAny
    case "bowelMovement":
      presentedActionSheet = LogBowelMovementView(performDismiss: dismiss).asAny
    case "bloodPressure":
      presentedActionSheet = LogBloodPressureView(performDismiss: dismiss).asAny
    case "voice":
      presentedActionSheet = VoiceLogView(meal: .suggested, performDismiss: dismiss).asAny
    default:
      // Unknown action, show actions list
      presentedActionSheet = ActionsView(performDismiss: dismiss).asAny
    }
  }
}

#Preview {
  PreviewEnvironment {
    RootView()
  }
}
