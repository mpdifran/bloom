//
//  FoodItemVerificationView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import SwiftUI

struct FoodItemVerificationView: View {

  @ObservedObject private var viewModel = FoodItemVerificationViewModel.shared

  @State private var selectedItem: FoodItem?

  var body: some View {
    NavigationSplitView {
      List(viewModel.foodItems, selection: $selectedItem) { item in
        Text(item.name)
          .tag(item)
      }
    } detail: {
      if let selectedItem {
        FoodItemDetailView(foodItem: selectedItem)
      } else {
        Text("No food items to verify")
      }
    }
    .task {
      await viewModel.loadItems()
    }
  }
}

#Preview {
  FoodItemVerificationView()
}
