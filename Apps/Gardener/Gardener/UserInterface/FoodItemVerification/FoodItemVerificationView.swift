//
//  FoodItemVerificationView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import BloomModel
import SwiftUI

struct FoodItemVerificationView: View {

  @ObservedObject private var viewModel = FoodItemVerificationViewModel.shared

  @State private var selectedItem: AdminFoodItemRecord?

  var body: some View {
    List(viewModel.foodItems, selection: $selectedItem) { item in
      NavigationLink {
        FoodItemDetailView(foodItem: item)
      } label: {
        Text(item.name ?? "No name")
          .tag(item)
      }
    }
    .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 300)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        refreshButton
      }
    }
    .task {
      await viewModel.loadItems()
    }
  }
}

private extension FoodItemVerificationView {
  var refreshButton: some View {
    Button {
      Task {
        await viewModel.loadItems()
      }
    } label: {
      Image(systemName: "arrow.clockwise")
        .imageScale(.large)
    }
  }
}

#Preview {
  NavigationSplitView {
    FoodItemVerificationView()
  } detail: {
    Text("No Selection")
  }
}
