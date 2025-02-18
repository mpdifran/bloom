//
//  FoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct FoodItemCell: View {
  let food: FoodItem

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  private let foodItemLogModelActor = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

  @State private var saveComplete = false
  @State private var hasLoggedThisFoodItem = false
  @State private var error: Error?

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack(spacing: 4) {
          if food.isVerified {
            Image(systemName: "checkmark.shield.fill")
              .foregroundStyle(.white, .mutedGreen)
            Text("Verified")
              .foregroundStyle(.mutedGreen)
              .bold()
          }

          Text(food.brandName ?? "Unknown")
            .foregroundStyle(.secondary)
            .bold()

          if let country = food.country {
            FoodItemCountryFlagView(country: country)
          }
        }
        .font(.caption)

        HStack(alignment: .firstTextBaseline) {
          Text(food.name)
          if let flavour = food.flavour {
            Text(flavour)
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
        .bold()

        if
          let serving = food.servingName,
          let servingQuantity = food.servingQuantity
        {
          Text("\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
            .font(.caption)
        }
      }

      Spacer()

      if let calories = food.calories?.value {
        VStack(spacing: 0) {
          Text("\(calories.format())")
            .bold()
            .font(.title2)
            .foregroundStyle(.tint)
          Text("cals")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .fontDesign(.rounded)
      }

      Button {
        guard !hasLoggedThisFoodItem else { return }

        Task { await quickLogFood() }
      } label: {
        if !hasLoggedThisFoodItem {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(.tint, .tint.tertiary)
            .font(.largeTitle)
        } else {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.white, .tint)
            .font(.largeTitle)
        }
      }
      .sensoryFeedback(.success, trigger: saveComplete)
    }
    .cardContainer(fill: .background, stroke: .background.secondary)
    .alert(error: $error)
    .onChange(of: nutritionViewModel.suggestedMeal) { _, _ in
      Task { await checkForExistingFoodLog() }
    }
  }
}

private extension FoodItemCell {

  func quickLogFood() async {
    do {
      try await nutritionViewModel.log(
        foodItem: food,
        date: nutritionViewModel.date,
        meal: nutritionViewModel.suggestedMeal,
        numberOfServings: 1
      )
      hasLoggedThisFoodItem = true
      saveComplete.toggle()
      SoundPlayer.playLogHealthData()
    } catch {
      self.error = error
    }
  }

  func checkForExistingFoodLog() async {
    do {
      let existingFoodLog = try await foodItemLogModelActor.fetchLog(
        for: .now,
        meal: nutritionViewModel.suggestedMeal,
        foodItemID: food.id.value
      )

      hasLoggedThisFoodItem = existingFoodLog != nil
    } catch {
      print(error)
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      FoodItemCell(
        food: .Preview.unverifiedRitzCrackers
      )
      FoodItemCell(
        food: .Preview.ritzCrackers
      )
    }
    .padding()
  }
}
