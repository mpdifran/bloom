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
      Picker("", selection: $viewModel.foodItem.state) {
        ForEach(AdminFoodItemRecord.State.allCases) { state in
          Text(state.name)
            .tag(state)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 500)
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
        notesSection
        timestampSection
      }
      .formStyle(.grouped)
      .frame(minWidth: 350)
    }
  }

  var infoSection: some View {
    Section(header: Text("Basic Information")) {
      TextField("Brand Name", text: .init($viewModel.foodItem.brandName, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.brandName))

      TextField("Name", text: .init($viewModel.foodItem.name, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.name))

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
      UnitTextField("Calories", value: $viewModel.foodItem.calories, unit: "Cal")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calories))

      UnitTextField("Protein", value: $viewModel.foodItem.protein, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.protein))
    }
  }

  var carbsSection: some View {
    Section(header: Text("Carbohydrates")) {
      UnitTextField("Carbohydrates", value: $viewModel.foodItem.carbohydrates, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.carbohydrates))

      UnitTextField("Fiber", value: $viewModel.foodItem.fiber, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fiber))

      UnitTextField("Sugar", value: $viewModel.foodItem.sugar, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sugar))
    }
  }

  var fatSection: some View {
    Section(header: Text("Fat")) {
      UnitTextField("Fat", value: $viewModel.foodItem.fat, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fat))

      UnitTextField("Saturated Fat", value: $viewModel.foodItem.saturatedFat, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.saturatedFat))

      UnitTextField("Trans Fat", value: $viewModel.foodItem.transFat, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.transFat))

      UnitTextField("Polyunsaturated Fat", value: $viewModel.foodItem.polyunsaturatedFat, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.polyunsaturatedFat))

      UnitTextField("Monounsaturated Fat", value: $viewModel.foodItem.monounsaturatedFat, unit: "g")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.monounsaturatedFat))
    }
  }

  var vitaminSection: some View {
    Section(header: Text("Vitamins")) {
      UnitTextField("Vitamin A", value: $viewModel.foodItem.vitaminA, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminA))

      UnitTextField("Vitamin B6", value: $viewModel.foodItem.vitaminB6, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB6))

      UnitTextField("Vitamin B12", value: $viewModel.foodItem.vitaminB12, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB12))

      UnitTextField("Vitamin C", value: $viewModel.foodItem.vitaminC, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminC))

      UnitTextField("Vitamin D", value: $viewModel.foodItem.vitaminD, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminD))

      UnitTextField("Vitamin E", value: $viewModel.foodItem.vitaminE, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminE))
    }
  }

  var mineralSection: some View {
    Section(header: Text("Minerals")) {
      UnitTextField("Sodium", value: $viewModel.foodItem.sodium, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sodium))

      UnitTextField("Calcium", value: $viewModel.foodItem.calcium, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calcium))

      UnitTextField("Iron", value: $viewModel.foodItem.iron, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.iron))

      UnitTextField("Potassium", value: $viewModel.foodItem.potassium, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.potassium))

      UnitTextField("Magnesium", value: $viewModel.foodItem.magnesium, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.magnesium))

      UnitTextField("Zinc", value: $viewModel.foodItem.zinc, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.zinc))
    }
  }

  var otherNutrientsSection: some View {
    Section(header: Text("Other Nutrients")) {
      UnitTextField("Cholesterol", value: $viewModel.foodItem.cholesterol, unit: "mg")
        .changeIndicator(isChanged: viewModel.propertyChanged(\.cholesterol))
    }
  }

  var miscSection: some View {
    Section(header: Text("Miscellaneous Information")) {
      VStack(alignment: .leading) {
        TextField("Barcode", text: .init($viewModel.foodItem.barcode, replacingNilWith: ""))
          .textFieldStyle(.roundedBorder)
          .changeIndicator(isChanged: viewModel.propertyChanged(\.barcode))
        HStack {
          Spacer()
          Text("\(viewModel.foodItem.barcode?.count ?? 0) digits")
            .font(.caption)
        }
        Text("If code longer than 8 digits, pad with 0s until 13 digits long. 8 digit codes are fine.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.trailing, 40)
      }

      VStack(alignment: .leading) {
        Text("Ingredients")
        TextEditor(text: Binding($viewModel.foodItem.ingredients, replacingNilWith: ""))
          .frame(height: 60)
          .changeIndicator(isChanged: viewModel.propertyChanged(\.ingredients))

        Text("Ignore ingredients for now. If they're there, just make sure they're formatted nice and in English.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.trailing, 40)
      }

      Picker("Country", selection: $viewModel.foodItem.country) {
        ForEach(FoodItem.Country.allCases, id: \.self) { country in
          Text(country.rawValue)
            .tag(country)
        }
      }
      .changeIndicator(isChanged: viewModel.propertyChanged(\.country))

      TextField("Source", text: .init($viewModel.foodItem.source, replacingNilWith: ""))
        .changeIndicator(isChanged: viewModel.propertyChanged(\.source))
    }
  }

  var notesSection: some View {
    Section("Notes") {
      TextEditor(text: Binding($viewModel.foodItem.notes, replacingNilWith: ""))
        .frame(height: 120)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.notes))
    }
  }

  var timestampSection: some View {
    Section("Timestamps") {
      LabeledContent("Created At") {
        if let createdAt = viewModel.foodItem.createdAt {
          Text(createdAt.formatted(date: .abbreviated, time: .shortened))
        } else {
          Text("N/A")
        }
      }
      LabeledContent("Updated At") {
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
