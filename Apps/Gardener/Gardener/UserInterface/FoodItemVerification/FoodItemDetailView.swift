//
//  FoodItemDetailView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import SwiftUI

struct FoodItemDetailView: View {

  let foodItem: FoodItem

  var body: some View {
    VStack {
      Text(foodItem.name)
      Text(foodItem.brandName)
      AsyncImage(url: foodItem.nutritionLabel)
      AsyncImage(url: foodItem.packagingImage)
    }
  }
}

#Preview {
  let foodItem = FoodItem(
    id: UUID().uuidString,
    name: "Hot dog",
    brandName: "Franks",
    nutritionLabel: URL(string: "https://picsum.photos/200/300"),
    packagingImage: URL(string: "https://picsum.photos/200/300")
  )
  FoodItemDetailView(foodItem: foodItem)
}
