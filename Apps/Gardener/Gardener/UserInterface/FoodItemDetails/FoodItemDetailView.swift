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

  enum ImageTab: String, CaseIterable {
    case packaging = "Packaging"
    case nutritionLabel = "Nutrition Label"
  }

  @State private var selectedImageTab: ImageTab = .packaging
  @State private var isSaving = false
  @State private var isDeleting = false
  @State private var alertDetails: AlertDetails?
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?

  @State private var fatsUnit: NutritionUnit = .grams
  @State private var carbsUnit: NutritionUnit = .grams
  @State private var mineralsUnit: NutritionUnit = .milligrams
  @State private var vitaminsUnit: NutritionUnit = .micrograms

  @Environment(\.openURL) private var openURL

  init(viewModel: FoodItemDetailViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    HStack(spacing: 0) {
      images

      formView
    }
    .shelf {
      verifyShelfContent
    }
    .alert(alertDetails: $alertDetails)
    .alert(error: $viewModel.error)
    .confirmationDialog($confirmationDialogDetails)
  }
}

private extension FoodItemDetailView {
  var images: some View {
    VStack(spacing: 0) {
      Picker("", selection: $selectedImageTab) {
        ForEach(ImageTab.allCases, id: \.self) { tab in
          Text(tab.rawValue)
            .tag(tab)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()

      ScrollView {
        VStack {
          switch selectedImageTab {
          case .packaging:
            createImage(
              url: viewModel.packagingImage,
              rotationAngle: viewModel.packagingImageRotation,
              type: selectedImageTab
            )
          case .nutritionLabel:
            createImage(
              url: viewModel.nutritionLabel,
              rotationAngle: viewModel.nutritionLabelRotation,
              type: selectedImageTab
            )
          }
        }
        .padding()
      }
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

        ProminentButton("Nutrition Label", systemImage: "text.page.fill") {
          guard let url = URL(string: "https://www.google.ca/search?udm=2&q=\(viewModel.foodItem.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+\(viewModel.foodItem.brandName?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+\(viewModel.foodItem.flavour?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+Nutrition+Label") else { return }

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
  func createImage(url: URL?, rotationAngle: Double, type: ImageTab) -> some View {
      if let url {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            ProgressView()
          case .success(let image):
            ZStack(alignment: .topTrailing) {
              image
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(rotationAngle))

              HStack {
                Button {
                  viewModel.rotate(value: -90, image: type)
                } label: {
                  Image(systemName: "rotate.left.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.regularMaterial, in: Circle())
                }
                .padding(4)

                Button {
                  viewModel.rotate(value: 90, image: type)
                } label: {
                  Image(systemName: "rotate.right.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.regularMaterial, in: Circle())
                }
                .padding(4)
              }
            }
          case .failure(let error):
            ContentUnavailableView {
              Label("Failed to Load Image", systemImage: "photo.badge.exclamationmark.fill")
            } description: {
              VStack {
                Text("The image failed to load")
                Text(error.localizedDescription)
                Text(url.absoluteString)
                  .foregroundStyle(.blue)
                  .textSelection(.enabled)
              }
            } actions: {
              Button("Copy URL to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
                alertDetails = AlertDetails(
                  title: "Copied!",
                  message: "Copied the URL to your clipboard."
                )
              }
              .buttonStyle(.borderedProminent)
            }
          @unknown default:
            Text("Unknown error occurred")
          }
        }
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
        fatSection
        otherNutrientsSection
        carbsSection
        proteinSection
        mineralSection
        vitaminSection
        miscSection
        notesSection
        timestampSection
      }
      .formStyle(.grouped)
      .frame(minWidth: 300, maxWidth: 350)
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
    Section(header: Text("Energy")) {
      UnitTextField(.calories, value: $viewModel.foodItem.calories, unit: .constant(.calories), defaultUnit: .calories)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calories))
    }
  }

  var carbsSection: some View {
    Section(header: Text("Carbohydrates")) {
      Picker("Unit", selection: $carbsUnit) {
        let availableUnits: [NutritionUnit] = [.micrograms, .milligrams, .grams, .percentDV]
        ForEach(availableUnits, id: \.self) { unit in
          Text(unit.displayName)
            .tag(unit)
        }
      }

      UnitTextField(.carbs, value: $viewModel.foodItem.carbohydrates, unit: $carbsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.carbohydrates))

      UnitTextField(.fiber, value: $viewModel.foodItem.fiber, unit: $carbsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fiber))

      UnitTextField(.sugar, value: $viewModel.foodItem.sugar, unit: $carbsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sugar))
    }
  }

  var fatSection: some View {
    Section(header: Text("Fat")) {
      Picker("Unit", selection: $fatsUnit) {
        let availableUnits: [NutritionUnit] = [.micrograms, .milligrams, .grams, .percentDV]
        ForEach(availableUnits, id: \.self) { unit in
          Text(unit.displayName)
            .tag(unit)
        }
      }

      UnitTextField(.fat, value: $viewModel.foodItem.fat, unit: $fatsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.fat))

      UnitTextField(.saturatedFat, value: $viewModel.foodItem.saturatedFat, unit: $fatsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.saturatedFat))

      UnitTextField(.transFat, value: $viewModel.foodItem.transFat, unit: $fatsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.transFat))

      UnitTextField(.polyunsaturatedFat, value: $viewModel.foodItem.polyunsaturatedFat, unit: $fatsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.polyunsaturatedFat))

      UnitTextField(.monounsaturatedFat, value: $viewModel.foodItem.monounsaturatedFat, unit: $fatsUnit, defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.monounsaturatedFat))
    }
  }

  var proteinSection: some View {
    Section(header: Text("Protein")) {
      UnitTextField(.protein, value: $viewModel.foodItem.protein, unit: .constant(.grams), defaultUnit: .grams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.protein))
    }
  }

  var vitaminSection: some View {
    Section(header: Text("Vitamins")) {
      Picker("Unit", selection: $vitaminsUnit) {
        let availableUnits: [NutritionUnit] = [.micrograms, .percentDV]
        ForEach(availableUnits, id: \.self) { unit in
          Text(unit.displayName)
            .tag(unit)
        }
      }

      UnitTextField(.vitaminA, value: $viewModel.foodItem.vitaminA, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminA))

      UnitTextField(.vitaminB6, value: $viewModel.foodItem.vitaminB6, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB6))

      UnitTextField(.vitaminB12, value: $viewModel.foodItem.vitaminB12, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminB12))

      UnitTextField(.vitaminC, value: $viewModel.foodItem.vitaminC, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminC))

      UnitTextField(.vitaminD, value: $viewModel.foodItem.vitaminD, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminD))

      UnitTextField(.vitaminE, value: $viewModel.foodItem.vitaminE, unit: $vitaminsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.vitaminE))
    }
  }

  var mineralSection: some View {
    Section(header: Text("Minerals")) {
      Picker("Unit", selection: $mineralsUnit) {
        let availableUnits: [NutritionUnit] = [.micrograms, .milligrams, .percentDV]
        ForEach(availableUnits, id: \.self) { unit in
          Text(unit.displayName)
            .tag(unit)
        }
      }

      UnitTextField(.sodium, value: $viewModel.foodItem.sodium, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.sodium))

      UnitTextField(.calcium, value: $viewModel.foodItem.calcium, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.calcium))

      UnitTextField(.iron, value: $viewModel.foodItem.iron, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.iron))

      UnitTextField(.potassium, value: $viewModel.foodItem.potassium, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.potassium))

      UnitTextField(.magnesium, value: $viewModel.foodItem.magnesium, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.magnesium))

      UnitTextField(.zinc, value: $viewModel.foodItem.zinc, unit: $mineralsUnit, defaultUnit: .milligrams)
        .changeIndicator(isChanged: viewModel.propertyChanged(\.zinc))
    }
  }

  var otherNutrientsSection: some View {
    Section(header: Text("Other Nutrients")) {
      UnitTextField(.cholesterol, value: $viewModel.foodItem.cholesterol, unit: .constant(.milligrams), defaultUnit: .milligrams)
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
  let viewModel = FoodItemDetailViewModel(foodItem: foodItem, foodStore: BaseFoodStore())
  FoodItemDetailView(viewModel: viewModel)
}
