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
      VStack(alignment: .leading) {
        HStack(spacing: 4) {
          if foodItem.isVerified {
            Image(systemName: "checkmark.shield.fill")
              .foregroundStyle(.white, .mutedGreen)
            Text("Verified")
              .foregroundStyle(.mutedGreen)
              .bold()
          }

          Text(foodItem.brandName)
            .foregroundStyle(.secondary)
            .bold()
        }
        .font(.caption)

        HStack(alignment: .firstTextBaseline) {
          Text(foodItem.name)

          if foodItem.flavour.isNotEmpty {
            Text(foodItem.flavour)
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
        .bold()

        HStack(spacing: 4) {
          Text(servingDescription(foodItem: foodItem))
          Text("•")
          Text(servingAmountDescription(foodItem: foodItem))
        }
        .font(.caption)
      }

      Spacer()

      VStack(spacing: 0) {
        Text("\(foodItemLog.totalProtein.format()) g")
          .bold()
          .font(.title2)
          .foregroundStyle(.tint)
        Text("protein")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)

      VStack(spacing: 0) {
        Text("\(foodItemLog.totalCalories.format())")
          .bold()
          .font(.title2)
          .foregroundStyle(.tint)
        Text("cals")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)
    }
    .selectable()
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
  FoodItemLogCell(
    foodItemLog: .init(
      id: "1234",
      date: .now,
      meal: .breakfast,
      numberOfServings: 2,
      foodItem: .Preview.ritzCrackers
    )
  )
}
