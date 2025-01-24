//
//  CreateNewFoodItemView.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-01-23.
//

import SwiftUI

struct CreateNewFoodItemView: View {
  @Environment(\.dismissWindow) private var dismissWindow
    
  var body: some View {
    // TODO: maybe add a success diaglog
    Group {
      let viewModel = CreateNewFoodItemDetailViewModel {
        // TODO: This current closes all windows, maybe look into closing only the current window
        dismissWindow(id: GardenerAppWindowGroupID.createNewFoodItem.rawValue)
      }
      
      FoodItemDetailView(viewModel: viewModel)
    }
    .navigationTitle("Create a new food item")
  }
}
