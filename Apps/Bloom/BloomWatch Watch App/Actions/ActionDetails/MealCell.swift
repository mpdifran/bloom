//
//  MealCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-02.
//

import SwiftUI
import BloomFoundation
import WatchKit

struct MealCell: View {
  let meal: WatchMealItem
  let selectedMeal: WatchMeal
  let performDismiss: (() -> Void)?

  @State private var isLogging = false
  @State private var showingConfirmation = false

  var body: some View {
    Button(action: logMeal) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(meal.name)
            .font(.body)
            .bold()
            .lineLimit(2)

          Text(macrosDescription)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text("\(Int(meal.calories))")
          .font(.caption)
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
      }
    }
    .buttonStyle(.plain)
    .disabled(isLogging)
    .overlay {
      if isLogging {
        ProgressView()
      } else if showingConfirmation {
        Image(systemName: "checkmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.green)
      }
    }
  }

  private var macrosDescription: String {
    let protein = Int(meal.protein)
    let carbs = Int(meal.carbs)
    let fat = Int(meal.fat)
    return "\(protein)P • \(carbs)C • \(fat)F"
  }

  private func logMeal() {
    guard !isLogging else { return }

    isLogging = true

    Task {
      let success = await PendingFoodLogManager.shared.logMeal(
        mealRecordID: meal.id,
        meal: selectedMeal.rawValue
      )

      isLogging = false

      if success {
        WKInterfaceDevice.current().play(.success)
        showingConfirmation = true
        try? await Task.sleep(for: .seconds(1))
        performDismiss?()
      } else {
        WKInterfaceDevice.current().play(.failure)
      }
    }
  }
}

#Preview {
  List {
    MealCell(
      meal: WatchMealItem(
        id: "1",
        name: "Chicken and Rice",
        calories: 450,
        protein: 35,
        carbs: 40,
        fat: 12
      ),
      selectedMeal: .lunch,
      performDismiss: nil
    )
  }
}
