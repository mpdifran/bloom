//
//  FoodItemLogCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct FoodItemLogCell: View {
  let foodItem: FoodItemRecord?
  let totalCalories: Double
  let totalServingAmount: Double

  var body: some View {
    if let foodItem {
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
        Image(systemSymbol: .checkmarkShieldFill)
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

      Text("\(totalCalories.format()) cals")
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
    "\(totalServingAmount.format()) \(foodItem.servingUnitString ?? "")"
  }
}

#Preview {
  VStack {
    Spacer()
    FoodItemLogCell(
      foodItem: .Preview.ritzCrackers,
      totalCalories: 300,
      totalServingAmount: 2
    )
    Spacer()
  }
  .horizontallyCentered()
  .padding()
  .groupedBackground()
}
