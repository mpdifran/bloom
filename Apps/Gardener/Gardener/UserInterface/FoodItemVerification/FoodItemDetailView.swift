//
//  FoodItemDetailView.swift
//  Gardener
//
//  Created by Zach Radford on 2024-11-29.
//

import AppUI
import BloomModel
import SwiftUI

struct FoodItemDetailView: View {

  @ObservedObject private var viewModel: FoodItemDetailViewModel

  private let foodItem: AdminFoodItemRecord

  enum ImageTab: String, CaseIterable {
    case packaging = "Packaging"
    case nutritionLabel = "Nutrition Label"
  }

  @State private var selectedImageTab: ImageTab = .nutritionLabel
  @State private var isSaving = false
  @State private var isDeleting = false
  @State private var alertDetails: AlertDetails?
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?

  @Environment(\.openURL) private var openURL

  init(foodItem: AdminFoodItemRecord) {
    self.foodItem = foodItem

    viewModel = FoodItemDetailViewModel(foodItem: foodItem)
  }

  var body: some View {
    HStack(spacing: 48) {
      images

      formView
    }
    .padding(48)
    .shelf {
      verifyShelfContent
    }
    .alert(alertDetails: $alertDetails)
    .confirmationDialog($confirmationDialogDetails)
  }
}

private extension FoodItemDetailView {
  var images: some View {
    ScrollView {
      VStack(spacing: 48) {
        Picker("", selection: $selectedImageTab) {
          ForEach(ImageTab.allCases, id: \.self) { tab in
            Text(tab.rawValue)
              .tag(tab)
          }
        }
        .pickerStyle(SegmentedPickerStyle())

        switch selectedImageTab {
        case .packaging:
          createImage(
            url: viewModel.packagingImage
          )
        case .nutritionLabel:
          createImage(
            url: viewModel.nutritionLabel
          )
        }
      }
      .padding()
    }
  }

  var verifyShelfContent: some View {
    VStack {
      Toggle(isOn: $viewModel.isVerified) {
        Text("Verify")
      }
      .toggleStyle(SwitchToggleStyle())
      .changeIndicator(isChanged: viewModel.propertyChanged(\.state))

      HStack {
        ProminentButton(
          "Save",
          systemImage: "tray.and.arrow.down",
          isLoading: isSaving
        ) {
          isSaving = true
          Task {
            await viewModel.save()
            isSaving = false
          }
        }
        .frame(maxWidth: 250)

        ProminentButton("Google", systemImage: "magnifyingglass") {
          guard let url = URL(string: "https://www.google.ca/search?udm=2&q=\(viewModel.foodItem.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+\(viewModel.foodItem.brandName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+\(viewModel.foodItem.flavour?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }

          openURL(url)
        }
        .tint(.blue)
        .frame(maxWidth: 160)

        if viewModel.foodItem.source == "Open Food Facts" {
          ProminentButton("Open Food Facts") {
            guard
              let barcode = viewModel.foodItem.barcode,
              let url = URL(string: "https://world.openfoodfacts.org/product/\(barcode)")
            else { return }

            openURL(url)
          }
          .tint(.blue)
          .frame(maxWidth: 160)
        }

        Button(role: .destructive) {
          confirmationDialogDetails = ConfirmationDialogDetails(
            title: "Are Your Sure?",
            message: "This will permanently delete this item.",
            buttons: [
              .init(title: "Delete", role: .destructive) {
                isDeleting = true
                Task {
                  await viewModel.delete()
                  // TODO: Zach - show in UI that item was deleted or transition to different item.
                  isDeleting = false
                }
              }
            ]
          )
        } label: {
          Image(systemName: "trash")
            .bold()
            .padding(6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
      }
    }
  }

  @ViewBuilder
  func createImage(url: URL?) -> some View {
      if let url {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .scaledToFit()
        } placeholder: {
          ProgressView()
        }
        .frame(width: 450)
      } else {
        Text("Not Found")
      }
  }

  var formView: some View {
    ScrollView {
      Form {
        infoSection
        servingSection
        macroSection
        carbsSection
        fatSection
        otherNutrientsSection
        mineralSection
        vitaminSection
        miscSection
      }
      .frame(minWidth: 350)
    }
  }

  var infoSection: some View {
    Section(header: Text("Basic Information")) {
      TextField("Name", text: .init($viewModel.foodItem.name, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.name))

      TextField("Brand Name", text: .init($viewModel.foodItem.brandName, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.brandName))

      TextField("Flavour", text: .init($viewModel.foodItem.flavour, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.flavour))

      Picker("Category", selection: $viewModel.foodItem.category) {
        ForEach(AdminFoodItemRecord.Category.allCases, id: \.self) { category in
          Text(category.rawValue)
            .tag(category)
        }
      }
      .changeIndicator(isChanged: viewModel.propertyChanged(\.category))
    }
  }

  var servingSection: some View {
    Section("Serving Info") {
      TextField("Serving Name", text: .init($viewModel.foodItem.servingName, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.servingName))

      TextField("Serving Value", value: $viewModel.foodItem.servingValue, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.servingValue))

      TextField("Serving Unit", text: .init($viewModel.foodItem.servingUnit, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.servingUnit))
    }
  }

  var macroSection: some View {
    Section(header: Text("Macros")) {
      TextField("Calories", value: $viewModel.foodItem.calories, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calories))

      TextField("Protein", value: $viewModel.foodItem.protein, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.protein))
    }
  }

  var carbsSection: some View {
    Section(header: Text("Carbohydrates")) {
      TextField("Carbohydrates", value: $viewModel.foodItem.carbohydrates, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.carbohydrates))

      TextField("Fiber", value: $viewModel.foodItem.fiber, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fiber))

      TextField("Sugar", value: $viewModel.foodItem.sugar, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sugar))
    }
  }

  var fatSection: some View {
    Section(header: Text("Fat")) {
      TextField("Fat", value: $viewModel.foodItem.fat, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fat))

      TextField("Saturated Fat", value: $viewModel.foodItem.saturatedFat, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.saturatedFat))

      TextField("Trans Fat", value: $viewModel.foodItem.transFat, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.transFat))

      TextField("Polyunsaturated Fat", value: $viewModel.foodItem.polyunsaturatedFat, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.polyunsaturatedFat))

      TextField("Monounsaturated Fat", value: $viewModel.foodItem.monounsaturatedFat, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.monounsaturatedFat))
    }
  }

  var vitaminSection: some View {
    Section(header: Text("Vitamins")) {
      TextField("Vitamin A", value: $viewModel.foodItem.vitaminA, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminA))

      TextField("Vitamin B6", value: $viewModel.foodItem.vitaminB6, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB6))

      TextField("Vitamin B12", value: $viewModel.foodItem.vitaminB12, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB12))

      TextField("Vitamin C", value: $viewModel.foodItem.vitaminC, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminC))

      TextField("Vitamin D", value: $viewModel.foodItem.vitaminD, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminD))

      TextField("Vitamin E", value: $viewModel.foodItem.vitaminE, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminE))
    }
  }

  var mineralSection: some View {
    Section(header: Text("Minerals")) {
      TextField("Sodium", value: $viewModel.foodItem.sodium, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sodium))

      TextField("Calcium", value: $viewModel.foodItem.calcium, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calcium))

      TextField("Iron", value: $viewModel.foodItem.iron, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.iron))

      TextField("Potassium", value: $viewModel.foodItem.potassium, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.potassium))

      TextField("Magnesium", value: $viewModel.foodItem.magnesium, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.magnesium))

      TextField("Zinc", value: $viewModel.foodItem.zinc, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.zinc))
    }
  }

  var otherNutrientsSection: some View {
    Section(header: Text("Other Nutrients")) {
      TextField("Cholesterol", value: $viewModel.foodItem.cholesterol, format: .number)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.cholesterol))
    }
  }

  var miscSection: some View {
    Section(header: Text("Miscellaneous Information")) {
      TextField("Barcode", text: .init($viewModel.foodItem.barcode, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.barcode))
      Text("\(viewModel.foodItem.barcode?.count ?? 0) digits")
        .font(.caption)
      Text("If code longer than 8 digits, pad with 0s until 13 digits long. 8 digit codes are fine.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.trailing, 40)

      TextField("Ingredients", text: .init($viewModel.foodItem.ingredients, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.ingredients))
      Text("Ignore ingredients for now. If they're there, just make sure they're formatted nice and in English.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.trailing, 40)

      Picker("Country", selection: $viewModel.foodItem.country) {
        ForEach(FoodItem.Country.allCases, id: \.self) { country in
          Text(country.rawValue)
            .tag(country)
        }
      }
      .changeIndicator(isChanged: viewModel.propertyChanged(\.country))

      TextField("Source", text: .init($viewModel.foodItem.source, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.source))

      HStack {
        Text("Created At")
        Spacer()
        if let createdAt = viewModel.foodItem.createdAt {
          Text(createdAt.formatted(date: .abbreviated, time: .shortened))
        } else {
          Text("N/A")
        }
      }

      HStack {
        Text("Updated At")
        Spacer()
        if let updatedAt = viewModel.foodItem.updatedAt {
          Text(updatedAt.formatted(date: .abbreviated, time: .shortened))
        } else {
          Text("N/A")
        }
      }
    }
  }
}

private struct ChangeIndicatorModifier: ViewModifier {
  let isChanged: Bool

  func body(content: Content) -> some View {
    content
      .padding(2)
      .overlay(
        RoundedRectangle(cornerRadius: 5)
          .stroke(isChanged ? Color.yellow : Color.clear, lineWidth: 2)
      )
  }
}

private extension View {
  func changeIndicator(isChanged: Bool) -> some View {
    self.modifier(ChangeIndicatorModifier(isChanged: isChanged))
  }
}

#Preview {
  let foodItem = AdminFoodItemRecord(id: FoodItemIdentifier(UUID().uuidString))
  FoodItemDetailView(foodItem: foodItem)
}
