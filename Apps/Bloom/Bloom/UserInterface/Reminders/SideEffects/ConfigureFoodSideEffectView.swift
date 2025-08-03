import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols
import BloomModel

struct ConfigureFoodSideEffectView: View {
  let existingSideEffect: ReminderSideEffect?
  let onSave: (ReminderSideEffect) -> Void

  init(
    existingSideEffect: ReminderSideEffect? = nil,
    onSave: @escaping (ReminderSideEffect) -> Void
  ) {
    self.existingSideEffect = existingSideEffect
    self.onSave = onSave

    // Initialize state from existing side effect
    if let existingSideEffect = existingSideEffect,
       let config = existingSideEffect.decodeConfiguration(as: LogFoodSideEffectConfig.self) {
      _servingSize = State(initialValue: config.servingSize)
      _selectedMeal = State(initialValue: config.meal)
      // Food item will be loaded in loadFoodItemIfNeeded()
    }
  }

  @FocusState private var isFocused: Bool

  @State private var selectedFood: FoodItemRecord?
  @State private var servingSize: Double = 1.0
  @State private var selectedMeal: FoodItemLog.Meal = .snack
  @State private var showingFoodPicker = false
  @State private var isLoadingFoodItem = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView {
        VStack {
          foodSection
          detailsSection
        }
      }
      .task {
        await loadFoodItemIfNeeded()
      }
      .navigationTitle(existingSideEffect == nil ? "Add Food" : "Edit Food")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .shelf {
        if isFocused {
          Button {
            isFocused = false
          } label: {
            Text("Done")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        } else {
          Button {
            saveAction()
          } label: {
            Text("Save")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .disabled(selectedFood == nil)
        }
      }
      .sheet(isPresented: $showingFoodPicker) {
        FoodItemPicker { foodItem in
          handleFoodItemSelection(foodItem)
        }
      }
    }
  }
}

private extension ConfigureFoodSideEffectView {

  var foodSection: some View {
    VStack {
      SectionTitleView("Food Item")
        .padding(.horizontal)

      HStack {
        if let food = selectedFood {
          VStack(alignment: .leading, spacing: 4) {
            Text(food.name)
              .font(.body)
              .fontWeight(.medium)
              .foregroundStyle(.primary)

            if food.brandName.isNotEmpty {
              Text(food.brandName)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        } else {
          Text("Select Food Item")
            .foregroundStyle(.accent)
        }

        Spacer()

        Image(systemSymbol: .chevronRight)
          .foregroundStyle(.tertiary)
          .font(.caption)
      }
      .selectable()
      .onTapGesture {
        showingFoodPicker = true
      }
      .cardContainer()
    }
  }
  
  var detailsSection: some View {
    VStack {
      SectionTitleView("Details")
        .padding(.horizontal)

      VStack {
        LabeledContent("Meal") {
          Picker("", selection: $selectedMeal) {
            ForEach(FoodItemLog.Meal.allCases) { meal in
              Text(meal.name)
                .tag(meal)
            }
          }
        }
        .frame(minHeight: 50)

        Divider()

        LabeledContent("Number of Servings") {
          TextField("", value: $servingSize, formatter: NumberFormatter.threeDecimalPlaces)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(width: 70)
            .fontDesign(.rounded)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .selectAllTextOnBeginEditing()
        }
        .frame(minHeight: 50)
      }
      .cardContainer()
    }
  }
  
  func saveAction() {
    guard let food = selectedFood else { return }
    
    let sideEffect = ReminderSideEffect.logFood(
      foodItem: food,
      servingSize: servingSize,
      meal: selectedMeal
    )
    
    if let existingSideEffect = existingSideEffect {
      sideEffect.id = existingSideEffect.id
    }
    
    onSave(sideEffect)
  }
  
  func handleFoodItemSelection(_ foodItem: FoodItem) {
    // Convert FoodItem (from BloomModel) to FoodItemRecord (from DataContainer)
    // Note: This creates a new FoodItemRecord instance - in a production app,
    // you might want to fetch the existing record from the database instead
    let foodItemRecord = FoodItemRecord(
      id: foodItem.id.value,
      name: foodItem.name,
      brandName: foodItem.brandName ?? "",
      flavour: foodItem.flavour ?? "",
      rawCountry: foodItem.country,
      calories: foodItem.calories?.value ?? 0,
      protein: foodItem.protein?.value ?? 0,
      carbohydrates: foodItem.carbohydrates?.value ?? 0,
      fat: foodItem.fat?.value ?? 0,
      saturatedFat: foodItem.saturatedFat?.value,
      transFat: foodItem.transFat?.value,
      polyunsaturatedFat: foodItem.polyunsaturatedFat?.value,
      monounsaturatedFat: foodItem.monounsaturatedFat?.value,
      fiber: foodItem.fiber?.value,
      sugar: foodItem.sugar?.value,
      cholesterol: foodItem.cholesterol?.value,
      sodium: foodItem.sodium?.value,
      calcium: foodItem.calcium?.value,
      iron: foodItem.iron?.value,
      potassium: foodItem.potassium?.value,
      magnesium: foodItem.magnesium?.value,
      zinc: foodItem.zinc?.value,
      vitaminA: foodItem.vitaminA?.value,
      vitaminB6: foodItem.vitaminB6?.value,
      vitaminB12: foodItem.vitaminB12?.value,
      vitaminC: foodItem.vitaminC?.value,
      vitaminD: foodItem.vitaminD?.value,
      vitaminE: foodItem.vitaminE?.value,
      servingName: foodItem.servingName,
      servingUnitString: foodItem.servingQuantity?.unit,
      servingValue: foodItem.servingQuantity?.value,
      ingredients: foodItem.ingredients,
      category: foodItem.category.asFoodItemRecordCategory,
      isVerified: foodItem.isVerified
    )
    
    selectedFood = foodItemRecord
    showingFoodPicker = false
  }
  
  func loadFoodItemIfNeeded() async {
    guard let existingSideEffect = existingSideEffect,
          selectedFood == nil else { return }
    
    // Try to get food info from configuration first
    if let config = existingSideEffect.decodeConfiguration(as: LogFoodSideEffectConfig.self) {
      isLoadingFoodItem = true
      
      do {
        let foodItemActor = FoodItemModelActor.standard()
        if let foodItemDTO = try await foodItemActor.fetchFoodItem(for: config.foodItemID) {
          await MainActor.run {
            // Convert DTO back to model for UI - this is a temporary approach
            // In a more robust implementation, we'd work with DTOs throughout
            let foodItem = FoodItemRecord(
              id: foodItemDTO.id,
              name: foodItemDTO.name,
              brandName: foodItemDTO.brandName,
              flavour: foodItemDTO.flavour,
              rawCountry: foodItemDTO.rawCountry,
              calories: foodItemDTO.calories,
              protein: foodItemDTO.protein,
              carbohydrates: foodItemDTO.carbohydrates,
              fat: foodItemDTO.fat,
              saturatedFat: foodItemDTO.saturatedFat,
              transFat: foodItemDTO.transFat,
              polyunsaturatedFat: foodItemDTO.polyunsaturatedFat,
              monounsaturatedFat: foodItemDTO.monounsaturatedFat,
              fiber: foodItemDTO.fiber,
              sugar: foodItemDTO.sugar,
              cholesterol: foodItemDTO.cholesterol,
              sodium: foodItemDTO.sodium,
              calcium: foodItemDTO.calcium,
              iron: foodItemDTO.iron,
              potassium: foodItemDTO.potassium,
              magnesium: foodItemDTO.magnesium,
              zinc: foodItemDTO.zinc,
              vitaminA: foodItemDTO.vitaminA,
              vitaminB6: foodItemDTO.vitaminB6,
              vitaminB12: foodItemDTO.vitaminB12,
              vitaminC: foodItemDTO.vitaminC,
              vitaminD: foodItemDTO.vitaminD,
              vitaminE: foodItemDTO.vitaminE,
              servingName: foodItemDTO.servingName,
              servingUnitString: foodItemDTO.servingUnitString,
              servingValue: foodItemDTO.servingValue,
              ingredients: foodItemDTO.ingredients,
              category: foodItemDTO.category,
              isVerified: foodItemDTO.isVerified
            )
            selectedFood = foodItem
          }
        }
      } catch {
        // Handle error silently for now
        print("Failed to load food item: \(error)")
      }
      
      isLoadingFoodItem = false
    }
  }
}

extension FoodItem.Category {
  var asFoodItemRecordCategory: FoodItemRecord.Category? {
    switch self {
    case .generic:
      return .generic
    case .fastfood:
      return .fastfood
    case .restaurant:
      return .restaurant
    case .branded:
      return .branded
    case .aiGenerated:
      return .aiGenerated
    }
  }
}

#Preview {
  PreviewEnvironment {
    ConfigureFoodSideEffectView { sideEffect in
      print("Saved: \(sideEffect)")
    }
  }
}
