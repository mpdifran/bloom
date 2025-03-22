//
//  FoodItemLogFoodItemCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-20.
//

import SwiftUI
import DataContainer

struct FoodItemLogFoodItemCell: View {
  let foodItemServing: FoodItemServing
  @Binding var numberOfServings: Double

  var body: some View {
    VStack {
      HStack {
        if foodItemServing.foodItem?.isVerified == true {
          Image(systemSymbol: .checkmarkShieldFill)
            .foregroundStyle(.white, .mutedGreen)
            .fontDesign(.rounded)
            .bold()
        }

        VStack(alignment: .leading) {
          Text(foodItemServing.foodItem?.name ?? "")
            .fontDesign(.rounded)

          Text(subtitle)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .bold()
        .multilineTextAlignment(.leading)

        Spacer()

        Text("\(totalCalories.format()) cals")
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
          .contentTransition(.numericText(value: totalCalories))

        TextField("", value: $numberOfServings, formatter: NumberFormatter.threeDecimalPlaces)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 70)
          .fontDesign(.rounded)
          .keyboardType(.decimalPad)
          .selectAllTextOnBeginEditing()
      }

      Divider()

      FoodItemMacroDistribution(
        displayType: .small,
        protein: foodItemServing.foodItem?.protein,
        carbohydrates: foodItemServing.foodItem?.carbohydrates,
        fat: foodItemServing.foodItem?.fat,
        numberOfServings: numberOfServings
      )
    }
    .cardContainer()
  }
}

private extension FoodItemLogFoodItemCell {

  var subtitle: String {
    var components = [String]()
    if let brandName = foodItemServing.foodItem?.brandName, brandName.isNotEmpty {
      components.append(brandName)
    }
    if let flavour = foodItemServing.foodItem?.flavour, flavour.isNotEmpty {
      components.append(flavour)
    }
    if let formattedServingQuantity {
      components.append(formattedServingQuantity)
    }

    return components.joined(separator: " • ")
  }

  var totalCalories: Double {
    (foodItemServing.foodItem?.calories ?? 0) * numberOfServings
  }

  var formattedServingQuantity: String? {
    guard
      let servingValue = foodItemServing.foodItem?.servingValue,
      let servingUnit = foodItemServing.foodItem?.servingUnitString
    else { return nil }

    return "\(servingValue.format(using: .twoDecimalPlaces)) \(servingUnit)"
  }
}

#Preview {
  @Previewable @State var numberOfServings: Double = 2

  PreviewEnvironment {
    ScrollView {
      VStack {
        FoodItemLogFoodItemCell(
          foodItemServing: FoodItemServing(
            numberOfServings: 2,
            foodItem: .Preview.ritzCrackers
          ),
          numberOfServings: $numberOfServings
        )
      }
      .padding()
    }
    .groupedBackground()
  }
}
