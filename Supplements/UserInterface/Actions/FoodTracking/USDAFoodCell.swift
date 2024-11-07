//
//  USDAFoodCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI

struct USDAFoodCell: View {
    let food: USDAFood

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.brandName ?? "Unknown")
                    .bold()
                Text(food.brandOwner ?? "Unknown")
                    .font(.caption)
            }

            Spacer()

            Text("\(food.foodNutrients.count) nutrients")
        }
    }
}

#Preview {
    List {
        USDAFoodCell(
            food: .init(
                fdcId: 1,
                brandOwner: "Kellogg",
                brandName: "Vector",
                foodNutrients: [
                    .init(
                        nutrientId: 1003,
                        nutrientName: "Protein",
                        nutrientNumber: "203",
                        unitName: "G",
                        value: 8.47,
                        rank: 600,
                        indentLevel: 1,
                        foodNutrientId: 24514466,
                        percentDailyValue: nil
                    )
                ]
            )
        )
    }
}
