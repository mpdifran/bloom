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
        dismissWindow()
      }
      
      FoodItemDetailView(viewModel: viewModel)
    }
    .navigationTitle("Create a new food item")
  }
}
