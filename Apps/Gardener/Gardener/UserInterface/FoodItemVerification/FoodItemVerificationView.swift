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
    .onAppear {
      
    }
    .task {
      await viewModel.loadItems()
    }
    .onChange(of: viewModel.foodItems) {
      // Select first item by default if no selection.
      guard selectedItem == nil, let firstItem = viewModel.foodItems.first else { return }
      selectedItem = firstItem
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
