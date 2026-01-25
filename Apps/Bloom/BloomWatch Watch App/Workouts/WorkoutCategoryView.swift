//
//  WorkoutCategoryView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth
import HealthKit
import AppUI

// MARK: - All Workouts Sheet

struct WorkoutCategoryView: View {
  @State private var presentedNavigationDestination: AnyView?

  var body: some View {
    NavigationStack {
      List {
        ForEach(WorkoutCategory.allCases) { category in
          WorkoutCategoryCell(
            title: category.rawValue,
            workoutTypes: category.workoutTypes
          )
          .onTapGesture {
            presentedNavigationDestination = WorkoutCategoryDetailsView(workoutCategory: category).asAny
          }
        }
      }
      .listStyle(.carousel)
      .navigationDestination($presentedNavigationDestination)
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutCategoryView()
    }
  }
}
