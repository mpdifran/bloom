//
//  EdamamFoodCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI

struct EdamamFoodCell: View {
    let food: Supplements.Components.Schemas.Food

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.label ?? "Unknown")
                    .bold()
                Text(food.brand ?? "Unknown")
                    .font(.caption)
            }

            Spacer()

            Text("\(food.nutrients?.additionalProperties.count ?? 0) nutrients")
        }
    }
}
