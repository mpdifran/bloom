//
//  FoodItemLogCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import SwiftUI
import DataContainer

struct FoodItemLogCell: View {
  let foodItemLog: FoodItemLog

  var body: some View {
    if let foodItem = foodItemLog.foodItem {
      contentView(foodItem: foodItem)
    } else {
      EmptyView()
    }
  }
}

private extension FoodItemLogCell {

  @ViewBuilder
  func contentView(foodItem: FoodItemRecord) -> some View {
    HStack {
      if foodItem.isVerified {
        Image(systemName: "checkmark.shield.fill")
          .foregroundStyle(.white, .mutedGreen)
          .fontDesign(.rounded)
          .bold()
      }

      VStack(alignment: .leading) {
        Text(foodItem.name)
          .fontDesign(.rounded)
          .bold()

        Text(subtitle(for: foodItem))
          .bold()
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      Text("\(foodItemLog.totalCalories.format()) cals")
        .font(.subheadline)
        .bold()
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)

      DisclosureIndicator()
    }
    .selectable()
    .cardContainer()
  }
}

private extension FoodItemLogCell {

  func subtitle(for foodItem: FoodItemRecord) -> String {
    var components = [String]()
    if foodItem.brandName.isNotEmpty {
      components.append(foodItem.brandName)
    }
    if foodItem.flavour.isNotEmpty {
      components.append(foodItem.flavour)
    }

    components.append(servingAmountDescription(foodItem: foodItem))

    return components.joined(separator: " • ")
  }

  func servingAmountDescription(foodItem: FoodItemRecord) -> String {
    "\(foodItemLog.totalServingAmount.format()) \(foodItem.servingUnitString ?? "")"
  }

  func servingDescription(foodItem: FoodItemRecord) -> String {
    "\(foodItemLog.numberOfServings.format(using: .oneDecimalPlace)) servings"
  }
}

#Preview {
  VStack {
    Spacer()
    FoodItemLogCell(
      foodItemLog: FoodItemLog(
        id: "1234",
        date: .now,
        meal: .breakfast,
        numberOfServings: 2,
        foodItem: .Preview.ritzCrackers
      )
    )
    Spacer()
  }
  .horizontallyCentered()
  .padding()
  .groupedBackground()
}
