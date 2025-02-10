//
//  AIScanFoodItemSuggetionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-10.
//

import SwiftUI
import BloomModel

struct AIScanFoodItemSuggetionCell: View {
  let foodItemServing: FoodItemServing
  let addItem: () -> Void

  var body: some View {
    HStack {
      foodDetailsContentView

      Spacer()

      addButton
    }
    .cardContainer(fill: .background, stroke: .background.secondary)
  }
}

private extension AIScanFoodItemSuggetionCell {

  var food: FoodItem {
    foodItemServing.foodItem
  }

  var foodDetailsContentView: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        if food.isVerified {
          Image(systemName: "checkmark.shield.fill")
            .foregroundStyle(.white, .mutedGreen)
          Text("Verified")
            .foregroundStyle(.mutedGreen)
            .bold()
        }

        if let brandName = food.brandName, brandName.isNotEmpty {
          Text(brandName)
            .foregroundStyle(.secondary)
            .bold()
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
  }

  var addButton: some View {
    Button {
      addItem()
    } label: {
      Image(systemName: "plus.circle.fill")
        .foregroundStyle(.white, .tint)
        .font(.title)
    }
  }
}

#Preview {
  AIScanFoodItemSuggetionCell(
    foodItemServing: FoodItemServing(
      serving: 2,
      foodItem: .Preview.ritzCrackers
    )
  ) {

  }
  .tint(.mutedGreen)
  .padding()
}
