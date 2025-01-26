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
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          if foodItem.isVerified {
            Image(systemName: "checkmark.shield.fill")
              .foregroundStyle(.white, .mutedGreen)
          }
          Text(foodItem.name)
        }
        .fontDesign(.rounded)
        .bold()

        HStack(alignment: .firstTextBaseline, spacing: 2) {
          if foodItem.brandName.isNotEmpty {
            Text(foodItem.brandName)
            Text("•")
          }

          if foodItem.flavour.isNotEmpty {
            Text(foodItem.flavour)
            Text("•")
          }

          Text(servingAmountDescription(foodItem: foodItem))
        }
        .bold()
        .foregroundStyle(.secondary)
        .font(.caption)
      }

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
      foodItemLog: .init(
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
