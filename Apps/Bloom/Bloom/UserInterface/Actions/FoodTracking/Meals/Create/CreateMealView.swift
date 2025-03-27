//
//  CreateMealView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import BloomModel
import DataContainer

struct CreateMealView: View {

  @State private var image: UIImage?
  @State private var name: String = ""
  @State private var foodItems = [FoodItem]()
  @State private var foodItemsServings = [FoodItemIdentifier: Double]()

  @FocusState private var isFocused: Bool
  @FocusState private var focusedFoodItem: FoodItemIdentifier?
  @State private var saveCompleteToggle = false
  @State private var presentedSheet: AnyView?

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          mealDetailsSection
          macroSummarySection
          foodItemsSection
        }
        .horizontallyCentered()
        .padding()
      }
      .groupedBackground()
      .navigationTitle("New Meal")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .shelf {
        shelfContent
      }
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: foodItems)
    .animation(.default, value: image)
    .animation(.default, value: foodItemsServings)
    .sheet($presentedSheet)
  }
}

private extension CreateMealView {

  var mealDetailsSection: some View {
    HStack(spacing: 16) {
      Group {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(square: 100)
            .clipShape(
              RoundedRectangle(cornerRadius: 18)
            )
        } else {
          RoundedRectangle(cornerRadius: 18)
            .fill(.fill)
            .frame(square: 100)
            .overlay {
              Image(systemSymbol: .plus)
                .foregroundStyle(.fill.secondary)
                .bold()
                .font(.title)
            }
        }
      }
      .padding(8)

      VStack(alignment: .leading) {
        TextField("", text: $name, prompt: Text("Name"))
          .font(.title)
          .fontDesign(.rounded)
          .bold()
          .submitLabel(.done)
          .focused($isFocused)
      }
      .padding(.vertical)
      .padding(.trailing)
    }
    .cardContainer(includePadding: false)
  }

  var macroSummarySection: some View {
    VStack {
      Group {
        Text(totalCalories.format() + " ")
        +
        Text("Cal")
          .foregroundStyle(.secondary)
          .font(.title3)
      }
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .contentTransition(.numericText(value: totalCalories))

      Divider()

      FoodItemMacroDistribution(
        protein: totalProtein,
        carbohydrates: totalCarbs,
        fat: totalFat,
        numberOfServings: 1
      )
    }
    .cardContainer()
  }

  @ViewBuilder
  var foodItemsSection: some View {
    SectionTitleView("Food Items")
      .padding(.horizontal)

    VStack(spacing: 0) {
      ForEach(foodItems) { foodItem in
        CreateMealFoodItemCell(
          foodItem: foodItem,
          numberOfServings: Binding($foodItemsServings[foodItem.id], replacingNilWith: 1)
        ) {
          foodItems.removeAll(where: { $0.id == foodItem.id })
        }
        .focused($focusedFoodItem, equals: foodItem.id)
        .padding()

        Divider()
          .padding(.horizontal)
      }

      Button {
        presentedSheet = FoodItemPicker { foodItem in
          foodItems.append(foodItem)
        }.asAny
      } label: {
        Label("Add Food", systemSymbol: .plus)
          .horizontallyCentered()
          .frame(minHeight: 50)
      }
      .bold()
    }
    .cardContainer(includePadding: false)
  }

  @ViewBuilder
  var shelfContent: some View {
    if isFocused || focusedFoodItem != nil {
      Button {
        isFocused = false
        focusedFoodItem = nil
      } label: {
        Text("Done")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    } else {
      AsyncButton {
        try await save()
        dismiss()
      } label: {
        Text("Create")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .disabled(!canSave)
      .sensoryFeedback(.success, trigger: saveCompleteToggle)
    }
  }
}

private extension CreateMealView {

  var totalCalories: Double {
    foodItems.reduce(0) { partialResult, foodItem in
      let numberOfServings = foodItemsServings[foodItem.id, default: 1]
      return partialResult + (foodItem.calories?.value ?? 0) * numberOfServings
    }
  }

  var totalProtein: Double {
    foodItems.reduce(0) { partialResult, foodItem in
      let numberOfServings = foodItemsServings[foodItem.id, default: 1]
      return partialResult + (foodItem.protein?.value ?? 0) * numberOfServings
    }
  }

  var totalCarbs: Double {
    foodItems.reduce(0) { partialResult, foodItem in
      let numberOfServings = foodItemsServings[foodItem.id, default: 1]
      return partialResult + (foodItem.carbohydrates?.value ?? 0) * numberOfServings
    }
  }

  var totalFat: Double {
    foodItems.reduce(0) { partialResult, foodItem in
      let numberOfServings = foodItemsServings[foodItem.id, default: 1]
      return partialResult + (foodItem.fat?.value ?? 0) * numberOfServings
    }
  }
}

private extension CreateMealView {

  var canSave: Bool {
    name.isNotEmpty && foodItems.isNotEmpty
  }

  func save() async throws {
    guard name.isNotEmpty else {
      throw NSError(description: "Name must not be empty.")
    }
    guard foodItems.isNotEmpty else {
      throw NSError(description: "At least one food item must be added.")
    }

    var datesToUpdate = Set<Date>()
    try modelContext.savingTransaction {

      var mealItemRecords = [MealItemRecord]()

      for foodItem in foodItems {
        let (dates, foodItemRecord) = try modelContext.upsertAndMerge(foodItem: foodItem)

        let numberOfServings = foodItemsServings[foodItem.id, default: 1]

        let mealItemRecord = MealItemRecord(
          numberOfServings: numberOfServings,
          foodItem: foodItemRecord
        )
        modelContext.insert(mealItemRecord)
        mealItemRecords.append(mealItemRecord)
        datesToUpdate.formUnion(dates)
      }

      let meal = MealRecord(
        name: name,
        imageData: image?.pngData(),
        items: mealItemRecords
      )

      modelContext.insert(meal)
    }

    try await NutritionTrackingViewModel.shared.updateNutrition(for: datesToUpdate)

    saveCompleteToggle.toggle()
  }
}

#Preview {
  PreviewEnvironment {
    CreateMealView()
  }
}
