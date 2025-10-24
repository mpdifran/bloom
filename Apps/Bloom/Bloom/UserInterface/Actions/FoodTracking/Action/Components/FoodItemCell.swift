//
//  FoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomModel
import DataContainer
import CoreHealth

struct FoodItemCell: View {
  let foodItem: FoodItem

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  private let foodItemLogModelActor = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

  @State private var saveComplete = false
  @State private var hasLoggedThisFoodItem = false
  @State private var error: Error?

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    HStack {
      if foodItem.isVerified {
        Image(systemSymbol: .checkmarkShieldFill)
          .foregroundStyle(.white, .mutedGreen)
          .fontDesign(.rounded)
          .bold()
      }

      VStack(alignment: .leading) {
        Text(foodItem.name)
          .fontDesign(.rounded)
          .bold()

        Text(subtitle)
          .bold()
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      if let calories = foodItem.calories?.value {
        Text("\(calories.format()) cals")
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
      }

      AsyncButton {
        guard !hasLoggedThisFoodItem else { return }

        try await quickLogFood()
      } label: {
        if !hasLoggedThisFoodItem {
          Image(systemSymbol: .plusCircleFill)
            .foregroundStyle(.tint, .tint.tertiary)
            .font(.largeTitle)
        } else {
          Image(systemSymbol: .checkmarkCircleFill)
            .foregroundStyle(.white, .tint)
            .font(.largeTitle)
        }
      }
      .sensoryFeedback(.success, trigger: saveComplete)
    }
    .cardContainer()
    .alert(error: $error)
    .onChange(of: nutritionViewModel.suggestedMeal) { _, _ in
      Task { await checkForExistingFoodLog() }
    }
  }
}

private extension FoodItemCell {

  var subtitle: String {
    var components = [String]()
    if let brandName = foodItem.brandName, brandName.isNotEmpty {
      components.append(brandName)
    }
    if let flavour = foodItem.flavour, flavour.isNotEmpty {
      components.append(flavour)
    }
    if let formattedServingQuantity {
      components.append(formattedServingQuantity)
    }

    return components.joined(separator: " • ")
  }

  var formattedServingQuantity: String? {
    guard let quantity = foodItem.servingQuantity else { return nil }

    return "\(quantity.value.format(using: .twoDecimalPlaces)) \(quantity.unit)"
  }

  func quickLogFood() async throws {
    try await nutritionViewModel.log(
      modelContext: modelContext,
      foodItem: foodItem,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal,
      numberOfServings: 1
    )

    // Donate intent for Siri suggestions
    await IntentDonator.donateMealLog(
      foodItemServings: [FoodItemServingAmount(serving: 1, foodItem: foodItem)],
      meal: nutritionViewModel.suggestedMeal,
      numberOfServings: 1
    )

    hasLoggedThisFoodItem = true
    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }

  func checkForExistingFoodLog() async {
    do {
      let existingFoodLog = try await foodItemLogModelActor.fetchLog(
        for: .now,
        meal: nutritionViewModel.suggestedMeal,
        foodItemID: foodItem.id.value
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
        foodItem: .Preview.unverifiedRitzCrackers
      )
      FoodItemCell(
        foodItem: .Preview.ritzCrackers
      )
    }
    .padding()
  }
  .groupedBackground()
}
