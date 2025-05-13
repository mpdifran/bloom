//
//  FoodItemLogPickerHeader.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-27.
//

import SwiftUI

struct FoodItemLogPickerHeader: View {

  var body: some View {
    HStack(spacing: 8) {
      FoodItemLogDatePicker()
      MealPicker()
    }
  }
}

#Preview {
  FoodItemLogPickerHeader()
}
