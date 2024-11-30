//
//  FoodItemDetailView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import SwiftUI

struct FoodItemDetailView: View {

  @ObservedObject private var viewModel: FoodItemDetailViewModel

  private let foodItem: FoodItem

  init(foodItem: FoodItem) {
    self.foodItem = foodItem

    viewModel = FoodItemDetailViewModel(foodItem: foodItem)
  }

  var body: some View {
    ScrollView {
      HStack(spacing: 48) {
        images

        VStack {
          formView

          Spacer(minLength: 48)

          buttons
        }
      }
      .padding(48)
    }
  }
}

private extension FoodItemDetailView {
  var images: some View {
    VStack(spacing: 48) {
      AsyncImage(url: foodItem.packagingImage)
        .frame(width: 500)
      AsyncImage(url: foodItem.nutritionLabel)
        .frame(width: 500)
    }
  }

  var formView: some View {
    Form {
      TextField("Name", text: $viewModel.name)
      TextField("Brand Name", text: $viewModel.brandName)
      TextField("Calories", text: $viewModel.calories)
    }
    .frame(minWidth: 200)
  }

  var buttons: some View {
    HStack(spacing: 48) {
      Button {
        Task {
          await viewModel.fix()
        }
      } label: {
        Label("Fix", systemImage: "wrench.and.screwdriver")
      }

      Button {
        Task {
          await viewModel.verify()
        }
      } label: {
        Label("Verify", systemImage: "checkmark.circle")
      }
    }
  }
}

#Preview {
  let foodItem = FoodItem(
    id: UUID().uuidString,
    name: "Hot dog",
    brandName: "Franks",
    nutritionLabel: URL(string: "https://picsum.photos/200/300"),
    packagingImage: URL(string: "https://picsum.photos/200/300"),
    calories: 150
  )
  FoodItemDetailView(foodItem: foodItem)
}
