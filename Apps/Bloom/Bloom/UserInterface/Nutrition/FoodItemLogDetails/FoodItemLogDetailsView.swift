//
//  FoodItemLogDetailsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-20.
//

import SwiftUI
import AppUI
import SFSafeSymbols
import BloomModel
import DataContainer
import CoreHealth

struct FoodItemLogDetailsView: View {
  private let foodItemLog: FoodItemLog

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @FocusState private var isFocused: Bool
  @FocusState private var focusedServingID: String?

  @State private var saveComplete = false
  @State private var showDatePicker = false
  @State private var isSwipingItem = false
  @State private var error: Error?

  @State private var numberOfServings: Double
  @State private var foodItemNumberOfServings: [String: Double]
  @State private var date: Date
  @State private var meal: FoodItemLog.Meal
  
  // Mass vs Servings picker
  @State private var inputMode: InputMode = .servings
  @State private var massInput: Double = 0.0
  
  private enum InputMode: String, CaseIterable, Identifiable {
    case servings = "Servings"
    case mass = "Mass"
    
    var id: String { rawValue }
  }

  init(
    foodItemLog: FoodItemLog
  ) {
    self.foodItemLog = foodItemLog

    var foodItemServings = [String: Double]()
    for serving in foodItemLog.foodItemServings ?? [] {
      foodItemServings[serving.id] = serving.numberOfServings
    }

    self._numberOfServings = State(initialValue: foodItemLog.numberOfServings)
    self._foodItemNumberOfServings = State(initialValue: foodItemServings)
    self._date = State(initialValue: foodItemLog.date)
    self._meal = State(initialValue: foodItemLog.meal)
    
    // Calculate initial mass input based on current servings and serving quantity
    let primaryServingValue = foodItemLog.foodItemServings?.first?.foodItem?.servingValue
    let initialMass = Self.calculateMassFromServings(
      servings: foodItemLog.numberOfServings,
      servingValue: primaryServingValue
    )
    self._massInput = State(initialValue: initialMass)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          nameSection
          macrosSection
          editSection
          foodItemsSection
        }
        .padding()
      }
      .scrollDisabled(isSwipingItem)
      .groupedBackground()
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .shelf {
        shelfContent
      }
      .animation(.easeInOut, value: numberOfServings)
      .animation(.easeInOut, value: foodItemNumberOfServings)
      .alert(error: $error)
    }
  }
}

private extension FoodItemLogDetailsView {

  var nameSection: some View {
    HStack(spacing: 24) {
      if let image = foodItemLog.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(square: 100)
          .clipShape(
            RoundedRectangle(cornerRadius: 26)
          )
      }

      VStack(alignment: .leading) {
        Text(foodItemLog.name ?? "")
          .font(.title)
          .fontDesign(.rounded)
          .bold()

        Text("\(foodItemLog.foodItemServings?.count ?? 0) items")
          .font(.body)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .if(foodItemLog.image == nil) {
      $0.padding(.horizontal)
    }
  }

  var macrosSection: some View {
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
        protein: proteinPerServing,
        carbohydrates: carbsPerServing,
        fat: fatPerServing,
        numberOfServings: numberOfServings
      )
    }
    .cardContainer()
  }

  var dateMealPickers: some View {
    HStack(spacing: 0) {
      Spacer()

      Button {
        showDatePicker.toggle()
      } label: {
        HStack(spacing: 2) {
          Text(date, formatter: DateFormatter.justRelativeDateMedium)
          Image(systemSymbol: .chevronUpChevronDown)
            .font(.caption)
        }
        .padding()
      }
      .popover(isPresented: $showDatePicker) {
        DatePicker(selection: $date, displayedComponents: .date) {
          Text(date, formatter: DateFormatter.justRelativeDateMedium)
        }
        .datePickerStyle(.graphical)
        .frame(width: 300)
        .presentationCompactAdaptation(.popover)
      }
      .onChange(of: date) { _, _ in
        showDatePicker = false
      }

      Picker(meal.name, selection: $meal) {
        ForEach(FoodItemLog.Meal.allCases) { meal in
          Text(meal.name)
            .tag(meal)
        }
      }

      Spacer()
    }
  }

  var editSection: some View {
    VStack(spacing: 0) {
      dateMealPickers

      Divider()

      if !primaryServingDisplay.isEmpty {
        LabeledContent("Serving Size", value: primaryServingDisplay)
          .frame(minHeight: 60)

        Divider()
      }

      Group {
        if inputMode == .servings || !canShowMassInput {
          LabeledContent("Number of Servings") {
            TextField("", value: $numberOfServings, formatter: NumberFormatter.threeDecimalPlaces)
              .textFieldStyle(.roundedBorder)
              .multilineTextAlignment(.trailing)
              .frame(width: 70)
              .fontDesign(.rounded)
              .keyboardType(.decimalPad)
              .focused($isFocused)
              .selectAllTextOnBeginEditing()
          }
        } else {
          LabeledContent("Amount (\(massUnit))") {
            TextField("", value: $massInput, formatter: NumberFormatter.threeDecimalPlaces)
              .textFieldStyle(.roundedBorder)
              .multilineTextAlignment(.trailing)
              .frame(width: 70)
              .fontDesign(.rounded)
              .keyboardType(.decimalPad)
              .focused($isFocused)
              .selectAllTextOnBeginEditing()
              .onChange(of: massInput) { _, newValue in
                numberOfServings = Self.calculateServingsFromMass(
                  mass: newValue,
                  servingValue: primaryServingValue
                )
              }
          }
        }
      }
      .frame(minHeight: 60)
      .onChange(of: numberOfServings) { _, newValue in
        if inputMode == .servings {
          massInput = Self.calculateMassFromServings(
            servings: newValue,
            servingValue: primaryServingValue
          )
        }
      }

      if canShowMassInput {
        Divider()

        Picker("Input Mode", selection: $inputMode) {
          ForEach(InputMode.allCases) { mode in
            Text(mode.rawValue)
              .tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 12)
      }
    }
    .padding(.horizontal)
    .cardContainer(includePadding: false)
  }

  var foodItemsSection: some View {
    VStack {
      SectionTitleView("Food Items")
        .padding(.horizontal)

      VStack {
        ForEach(foodItemLog.foodItemServings ?? []) { serving in
          Swipeable(
            isSwipingItem: $isSwipingItem,
            actions: [
              SwipeAction(
                title: "Delete",
                symbol: .trash,
                tint: .mutedRed,
                action: {
                  Task {
                    await delete(serving)
                  }
                }
              )
            ]
          ) {
            FoodItemLogFoodItemCell(
              foodItemServing: serving,
              numberOfServings: Binding($foodItemNumberOfServings[serving.id], replacingNilWith: 1)
            )
            .focused($focusedServingID, equals: serving.id)
            .contextMenu {
              Button("Delete", systemSymbol: .trash, role: .destructive) {
                Task {
                  await delete(serving)
                }
              }
            }
          }
        }
      }
    }
  }
}

private extension FoodItemLogDetailsView {

  var totalCalories: Double {
    var total: Double = 0
    for serving in foodItemLog.foodItemServings ?? [] {
      total += foodItemNumberOfServings[serving.id, default: 1] * (serving.foodItem?.calories ?? 0)
    }
    total *= numberOfServings
    return total
  }

  var proteinPerServing: Double {
    var total: Double = 0
    for serving in foodItemLog.foodItemServings ?? [] {
      total += foodItemNumberOfServings[serving.id, default: 1] * (serving.foodItem?.protein ?? 0)
    }
    return total
  }

  var carbsPerServing: Double {
    var total: Double = 0
    for serving in foodItemLog.foodItemServings ?? [] {
      total += foodItemNumberOfServings[serving.id, default: 1] * (serving.foodItem?.carbohydrates ?? 0)
    }
    return total
  }

  var fatPerServing: Double {
    var total: Double = 0
    for serving in foodItemLog.foodItemServings ?? [] {
      total += foodItemNumberOfServings[serving.id, default: 1] * (serving.foodItem?.fat ?? 0)
    }
    return total
  }
}

private extension FoodItemLogDetailsView {

  @ViewBuilder
  var shelfContent: some View {
    if isFocused || focusedServingID != nil {
      Button {
        isFocused = false
        focusedServingID = nil
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
        Text("Update")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .disabled(!canSave)
      .sensoryFeedback(.success, trigger: saveComplete)
    }
  }
}

private extension FoodItemLogDetailsView {

  // MARK: - Mass/Servings Conversion

  static func calculateMassFromServings(servings: Double, servingValue: Double?) -> Double {
    guard let servingValue else { return 0.0 }
    return servings * servingValue
  }

  static func calculateServingsFromMass(mass: Double, servingValue: Double?) -> Double {
    guard let servingValue, servingValue > 0 else { return 0.0 }
    return mass / servingValue
  }

  var primaryServingValue: Double? {
    foodItemLog.foodItemServings?.first?.foodItem?.servingValue
  }

  var primaryServingUnit: String? {
    foodItemLog.foodItemServings?.first?.foodItem?.servingUnitString
  }

  var primaryServingDisplay: String {
    let primary = foodItemLog.foodItemServings?.first?.foodItem
    var result = primary?.servingName ?? ""
    if let value = primary?.servingValue, let unit = primary?.servingUnitString {
      result += result.isEmpty ? "\(value.formatted()) \(unit)" : " (\(value.formatted()) \(unit))"
    }
    return result
  }

  var massUnit: String {
    primaryServingUnit ?? "g"
  }

  var canShowMassInput: Bool {
    primaryServingValue != nil
  }

  var canSave: Bool {
    guard
      date == foodItemLog.date,
      meal == foodItemLog.meal,
      numberOfServings == foodItemLog.numberOfServings
    else {
      return true
    }

    for serving in foodItemLog.foodItemServings ?? [] {
      if serving.numberOfServings != foodItemNumberOfServings[serving.id, default: 1] {
        return true
      }
    }

    return false
  }

  func save() async throws {
    try await nutritionViewModel.update(
      modelContext: modelContext,
      foodItemLog: foodItemLog,
      numberOfServings: numberOfServings,
      foodItemNumberOfServings: foodItemNumberOfServings,
      date: date,
      meal: meal
    )

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }

  func delete(_ foodItemServing: FoodItemServing) async {
    do {
      try await nutritionViewModel.delete(modelContext: modelContext, foodItemServing: foodItemServing)
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    FoodItemLogDetailsView(
      foodItemLog: FoodItemLog(
        id: "123",
        name: "Crackers and Cheese",
        date: .now,
        meal: .snack,
        numberOfServings: 3,
        imageData: UIImage(named: "CrackersAndCheese")?.pngData(),
        foodItemServings: [
          FoodItemServing(
            numberOfServings: 2,
            foodItem: .Preview.ritzCrackers
          ),
          FoodItemServing(
            numberOfServings: 1,
            foodItem: .Preview.shreddedCheddar
          )
        ]
      )
    )
  }
}
