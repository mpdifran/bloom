//
//  NutritionMealView.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import DataContainer
import SwiftUI

struct NutritionMealView: View {

  let foodItemLogs: [FoodItemLog]
  let onCellTapped: (FoodItemLog) -> Void
  let onLogTapped: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      if foodItemLogs.isEmpty {
        Text("No Food Logged")
          .font(.title2)
          .foregroundStyle(.secondary)
          .bold()
          .padding()
          .padding()
      } else {
        ForEach(foodItemLogs) { foodItemLog in
          FoodItemLogCell(foodItemLog: foodItemLog)
            .id(foodItemLog.id)
            .transition(.blurReplace)
            .selectable()
            .onTapGesture {
              onCellTapped(foodItemLog)
            }
            .padding()
          Divider()
            .padding(.horizontal)
        }
      }

      if foodItemLogs.isEmpty {
        Divider()
          .padding(.horizontal)
      }

      Button {
        onLogTapped()
      } label: {
        Label("Log Food", systemImage: "plus")
          .horizontallyCentered()
      }
      .frame(height: 50)
      .bold()
    }
    .horizontallyCentered()
    .cardContainer(includePadding: false)
  }
}
