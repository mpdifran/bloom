//
//  CreateEditMealView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct CreateEditMealView: View {

  var existingMealRecord: MealRecord?

  init(existingMealRecord: MealRecord? = nil) {
    self.existingMealRecord = existingMealRecord

    guard let meal = existingMealRecord else { return }

    self._image = State(initialValue: meal.image)
    self._name = State(initialValue: meal.name)

    var foodItemsServings = [FoodItemIdentifier: Double]()
    var foodItems = [FoodItem]()
    for mealItem in meal.items ?? [] {
      guard let foodItem = mealItem.foodItem?.asNetworkFoodItem() else { continue }

      foodItemsServings[foodItem.id] = mealItem.numberOfServings
      foodItems.append(foodItem)
    }

    self._foodItemsServings = State(initialValue: foodItemsServings)
    self._foodItems = State(initialValue: foodItems)

    initialFoodItems = foodItems
    initialFoodItemsServings = foodItemsServings
  }

  private var initialFoodItems = [FoodItem]()
  private var initialFoodItemsServings = [FoodItemIdentifier: Double]()

  @State private var image: UIImage?
  @State private var name: String = "My Meal"
  @State private var foodItems = [FoodItem]()
  @State private var foodItemsServings = [FoodItemIdentifier: Double]()

  @FocusState private var isFocused: Bool
  @FocusState private var focusedFoodItem: FoodItemIdentifier?

  @State private var saveCompleteToggle = false
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          mealDetailsSection
          macroSummarySection
          foodItemsSection

          if isEditing {
            deleteSection
          }
        }
        .horizontallyCentered()
        .padding()
      }
      .groupedBackground()
      .navigationTitle(isEditing ? "Edit Meal" : "New Meal")
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
    .alert(error: $error)
  }
}

private extension CreateEditMealView {

  var mealDetailsSection: some View {
    HStack(alignment: .top, spacing: 8) {
      ImagePicker(image: $image, presentedSheet: $presentedSheet) {
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
        TextEditor(text: $name)
          .font(.title)
          .fontDesign(.rounded)
          .bold()
          .submitLabel(.done)
          .focused($isFocused)
          .frame(height: 100)
      }
      .padding(.vertical, 8)
      .padding(.trailing, 8)
    }
    .cardContainer(includePadding: false)
  }

  @ViewBuilder
  var macroSummarySection: some View {
    SectionTitleView("Macros")
      .padding(.horizontal)

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

  var deleteSection: some View {
    Button(role: .destructive) {
      confirmationDialogDetails = ConfirmationDialogDetails(
        title: "Are You Sure?",
        message: "Once you delete this meal, it can't be undone.",
        buttons: [
          ConfirmationDialogDetails.Button(
            title: "Delete",
            role: .destructive
          ) { delete() }
        ]
      )
    } label: {
      Label("Delete", systemSymbol: .trash)
        .bold()
        .horizontallyCentered()
    }
    .frame(height: 50)
    .cardContainer(includePadding: false)
    .confirmationDialog($confirmationDialogDetails)
    .padding(.top)
    .padding(.top)
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
        Text(isEditing ? "Save" : "Create")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .disabled(!canSave)
      .sensoryFeedback(.success, trigger: saveCompleteToggle)
    }
  }
}

private extension CreateEditMealView {

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

private extension CreateEditMealView {

  var isEditing: Bool {
    existingMealRecord != nil
  }

  var canSave: Bool {
    if let existingMealRecord {
      return
        existingMealRecord.name != name ||
        existingMealRecord.imageData != image?.pngData() ||
        initialFoodItems != foodItems ||
        initialFoodItemsServings != foodItemsServings
    } else {
      return name.isNotEmpty && foodItems.isNotEmpty
    }
  }

  func save() async throws {
    guard name.isNotEmpty else {
      throw NSError(description: "Name must not be empty.")
    }
    guard foodItems.isNotEmpty else {
      throw NSError(description: "At least one food item must be added.")
    }

    let foodItemServings = foodItems.map { foodItem in
      FoodItemServingAmount(
        serving: foodItemsServings[foodItem.id, default: 1],
        foodItem: foodItem
      )
    }

    if let existingMealRecord {
      try await nutritionViewModel.updateMeal(
        modelContext: modelContext,
        mealRecord: existingMealRecord,
        name: name,
        image: image,
        foodItemServings: foodItemServings
      )
    } else {
      try await nutritionViewModel.createMeal(
        modelContext: modelContext,
        name: name,
        image: image,
        foodItemServings: foodItemServings
      )
    }

    saveCompleteToggle.toggle()
  }

  func delete() {
    guard let model = existingMealRecord else { return }

    modelContext.delete(model)
    dismiss()
  }
}

#Preview("Create") {
  PreviewEnvironment {
    CreateEditMealView()
  }
}

#Preview("Edit") {
  PreviewEnvironment {
    CreateEditMealView(
      existingMealRecord: .Preview.crackersAndCheese
    )
  }
}
