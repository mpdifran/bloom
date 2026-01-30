//
//  FoodCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import BloomFoundation

struct FoodCell: View {
  let food: WatchFoodItem

  var body: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(food.name)
          .font(.footnote)
          .fontWeight(.medium)
          .lineLimit(2)

        if let brand = food.brandName {
          Text(brand)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)

      Text("\(Int(food.calories))")
        .font(.caption)
        .foregroundStyle(.secondary)
      + Text(" cal")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
  }
}

#Preview {
  List {
    FoodCell(food: WatchFoodItem(
      id: "1",
      name: "Chicken Breast",
      brandName: nil,
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      servingName: "100g"
    ))

    FoodCell(food: WatchFoodItem(
      id: "2",
      name: "Greek Yogurt",
      brandName: "Chobani",
      calories: 100,
      protein: 17,
      carbs: 6,
      fat: 0,
      servingName: "1 container"
    ))
  }
}
