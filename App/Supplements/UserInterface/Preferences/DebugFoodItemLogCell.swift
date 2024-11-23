//
//  DebugFoodItemLogCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import SwiftUI
import DataContainer

struct DebugFoodItemLogCell: View {
    let foodItemLog: FoodItemLog

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(foodItemLog.foodItem?.name ?? "Unknown")

                Text(foodItemLog.meal.rawValue)

                Text(foodItemLog.date.formatted(.dateTime))
            }

            Spacer()

            Text("\(foodItemLog.numberOfServings.format()) servings")
        }
    }
}

#Preview {
    DebugFoodItemLogCell(
        foodItemLog: .init(
            id: "123",
            date: .now,
            meal: .lunch,
            numberOfServings: 2,
            foodItem: .init(
                id: "456",
                name: "Crackers",
                brandName: "Ritz",
                flavour: "Low Sodium",
                calories: 120,
                protein: 1,
                carbohydrates: 13,
                fat: 4,
                servingName: "6 crackers",
                servingUnitString: "g",
                servingValue: 20,
                ingredients: nil,
                isVerified: true,
                logs: []
            )
        )
    )
}
