//
//  DebugFoodItemLogListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer

struct DebugFoodItemLogListView: View {

  @Query(sort: \FoodItemLog.date, order: .reverse) var foodItemLogs: [FoodItemLog]

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  @State private var error: Error?

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      List {
        ForEach(foodItemLogs) { log in
          DebugFoodItemLogCell(foodItemLog: log)
        }
        .onDelete { indexSet in
          Task {
            await deleteLogs(indexSet)
          }
        }
      }
      .navigationTitle("Debug Food Item Logs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .alert(error: $error)
  }
}

private extension DebugFoodItemLogListView {

  func deleteLogs(_ indexSet: IndexSet) async {
    let logs = indexSet.map({ foodItemLogs[$0] })

    do {
      try await nutritionViewModel.delete(modelContext: modelContext, foodItemLogs: logs)
    } catch {
      self.error = error
    }
  }
}

#Preview {
  NavigationStack {
    DebugFoodItemLogListView()
  }
}
