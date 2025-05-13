//
//  MealBindingPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-13.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct MealBindingPicker: View {
  @Binding var meal: FoodItemLog.Meal

  var body: some View {
    Menu {
      ForEach(FoodItemLog.Meal.allCases, id: \.self) { meal in
        Button(meal.name) {
          self.meal = meal
        }
      }
    } label: {
      HStack(spacing: 2) {
        Text(meal.name)
        Image(systemSymbol: .chevronUpChevronDown)
          .font(.caption)
      }
      .bold()
      .padding(.vertical)
    }
  }
}

#Preview {
  @Previewable @State var meal: FoodItemLog.Meal = .breakfast

  MealBindingPicker(meal: $meal)
}
