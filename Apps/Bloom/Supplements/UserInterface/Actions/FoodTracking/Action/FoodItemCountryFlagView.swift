//
//  FoodItemCountryFlagView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-14.
//

import SwiftUI
import BloomModel

struct FoodItemCountryFlagView: View {
  let country: FoodItem.Country

  var body: some View {
    Group {
      switch country {
      case .canada:
        Image(.canadaFlag)
          .resizable()
          .scaledToFit()
      case .usa:
        Image(.usaFlag)
          .resizable()
          .scaledToFit()
      }
    }
    .frame(height: 8)
    .border(.fill, width: 0.5)
  }
}

#Preview {
  FoodItemCountryFlagView(country: .canada)
  FoodItemCountryFlagView(country: .usa)
}
