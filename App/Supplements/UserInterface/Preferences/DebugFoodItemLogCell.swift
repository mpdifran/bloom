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
            foodItem: .Preview.ritzCrackers
        )
    )
}
