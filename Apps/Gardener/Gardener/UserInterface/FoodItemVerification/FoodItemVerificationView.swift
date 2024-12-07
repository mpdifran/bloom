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
        FoodItemCell(
          id: item.id.value,
          name: item.name,
          brandName: item.brandName,
          isVerified: item.state == .verified
        )
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

private struct FoodItemCell: View {
  let id: String
  let name: String?
  let brandName: String?
  let isVerified: Bool

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(id)
          .font(.subheadline)
          .foregroundColor(.gray)
        Text(name ?? "No Name")
          .font(.headline)
        if let brandName {
          Text(brandName)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Image(systemName: isVerified ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundColor(.white)
        .imageScale(.large)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  NavigationSplitView {
    FoodItemVerificationView()
  } detail: {
    Text("No Selection")
  }
}
