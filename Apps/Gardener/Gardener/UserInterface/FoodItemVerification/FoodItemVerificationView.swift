//
//  FoodItemVerificationView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import AdminBloomModel
import SwiftUI

struct FoodItemVerificationView: View {

  @ObservedObject private var foodStore = UnverifiedFoodStore.shared

  @State private var selectedItem: AdminFoodItemRecord?

  var body: some View {
    List(foodStore.foodItems, selection: $selectedItem) { item in
      NavigationLink {
        let viewModel = FoodItemDetailViewModel(foodItem: item, foodStore: foodStore)
        FoodItemDetailView(viewModel: viewModel)
      } label: {
        FoodItemCell(
          id: item.id.value,
          name: item.name,
          brandName: item.brandName,
          state: item.state
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
      await foodStore.loadItems()
    }
  }
}

private extension FoodItemVerificationView {
  var refreshButton: some View {
    Button {
      Task {
        await foodStore.loadItems()
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
  let state: AdminFoodItemRecord.State

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

      Group {
        switch state {
        case .needsAIProcessing:
          Image(systemName: "sparkles.rectangle.stack.fill")
            .foregroundStyle(.white, .blue)
        case .unverified:
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.white, .yellow)
        case .needsMoreInfo:
          Image(systemName: "questionmark.app.fill")
            .foregroundStyle(.white, .orange)
        case .verified:
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.white, .green)
        }
      }
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
