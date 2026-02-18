//
//  FoodItemDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-21.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomModel
import DataContainer
import CoreHealth

extension FoodItemDetailsView {
  enum Mode {
    case editAndView
    case viewOnly
  }
}

struct FoodItemDetailsView: View {
  let foodItem: BloomModel.FoodItem
  let existingFoodItemLog: FoodItemLog?
  let mode: Mode

  init(
    foodItem: BloomModel.FoodItem,
    existingFoodItemLog: FoodItemLog?,
    mode: Mode = .editAndView
  ) {
    self.foodItem = foodItem
    self.existingFoodItemLog = existingFoodItemLog
    self.mode = mode

    let initialServings: Double
    if let existingFoodItemLog {
      if let serving = existingFoodItemLog.serving(for: foodItem.id.value) {
        initialServings = serving.numberOfServings
      } else {
        initialServings = 1
      }
      self._date = State(initialValue: existingFoodItemLog.date)
      self._meal = State(initialValue: existingFoodItemLog.meal)
    } else {
      initialServings = 1
      self._date = State(initialValue: NutritionTrackingViewModel.shared.date)
      self._meal = State(initialValue: NutritionTrackingViewModel.shared.suggestedMeal)
    }
    self._numberOfServings = State(initialValue: initialServings)
    self._massInput = State(initialValue: Self.calculateMassFromServings(
      servings: initialServings,
      servingQuantity: foodItem.servingQuantity
    ))
  }

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var numberOfServings: Double
  @State private var date: Date
  @State private var meal: FoodItemLog.Meal
  @State private var showDatePicker = false
  @State private var saveComplete = false
  @State private var hasMarkedAsInaccurate = false
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  // Mass vs Servings picker
  @State private var inputMode: InputMode = .servings
  @State private var massInput: Double = 0.0

  private enum InputMode: String, CaseIterable, Identifiable {
    case servings = "Servings"
    case mass = "Mass"

    var id: String { rawValue }
  }

  @FocusState private var isFocused: Bool

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          nameSection
          macrosSection
          editSection

          FoodItemNutritionLabel(foodItem: foodItem)
            .cardContainer()

          accuracySection
        }
        .padding()
      }
      .groupedBackground()
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack {
            Text("Details")
              .bold()
            if foodItem.isVerified {
              HStack(spacing: 2) {
                Image(systemSymbol: .checkmarkShieldFill)
                  .foregroundStyle(.white, .mutedGreen)
                Text("Verified")
                  .foregroundStyle(.mutedGreen)
                  .bold()
              }
              .font(.caption)
              .fontDesign(.rounded)
            }
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
        ToolbarItem(placement: .primaryAction) {
          foodItemMenu
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
        } else if mode == .editAndView {
          AsyncButton {
            try await save()
            dismiss()
          } label: {
            Text(existingFoodItemLog == nil ? "Log" : "Update")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .disabled(!canSave)
          .sensoryFeedback(.success, trigger: saveComplete)
        }
      }
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
      .sensoryFeedback(.success, trigger: hasMarkedAsInaccurate)
      .animation(.easeInOut, value: numberOfServings)
      .animation(.easeInOut, value: inputMode)
      .sheet($presentedSheet)
      .alert(error: $error)
      .alert(alertDetails: $alertDetails)
    }
  }
}

private extension FoodItemDetailsView {

  var nameSection: some View {
    HStack(spacing: 24) {
      if let image = existingFoodItemLog?.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(square: 100)
          .clipShape(
            RoundedRectangle(cornerRadius: 26)
          )
      }

      VStack(alignment: .leading) {
        Group {
          if let brandName = foodItem.brandName {
            Text(brandName) + Text(" ") + Text(foodItem.name)
          } else {
            Text(foodItem.name)
          }
        }
        .font(.title)
        .fontDesign(.rounded)
        .bold()

        if let flavour = foodItem.flavour {
          Text(flavour)
            .font(.body)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
    }
    .if(existingFoodItemLog?.image == nil) {
      $0.padding(.horizontal)
    }
  }

  var caloriesValue: Double {
    (foodItem.calories?.value ?? 0) * numberOfServings
  }

  var macrosSection: some View {
    VStack {
      Group {
        Text(caloriesValue.format() + " ")
        +
        Text("Cals")
          .foregroundStyle(.secondary)
          .font(.title3)
      }
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .contentTransition(.numericText(value: caloriesValue))

      Divider()

      FoodItemMacroDistribution(
        protein: foodItem.protein?.value,
        carbohydrates: foodItem.carbohydrates?.value,
        fat: foodItem.fat?.value,
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
          Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
          Image(systemSymbol: .chevronUpChevronDown)
            .font(.caption)
        }
        .padding()
      }
      .popover(isPresented: $showDatePicker) {
        DatePicker(selection: $date, displayedComponents: .date) {
          Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
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

  var canEditDateAndMeal: Bool {
    guard let existingFoodItemLog else {
      return true
    }

    return existingFoodItemLog.hasSingleServing
  }

  var editSection: some View {
    VStack(spacing: 0) {
      if mode == .editAndView {
        if canEditDateAndMeal {
          dateMealPickers
          Divider()
        } else if let foodItemLog = existingFoodItemLog {
          Button {
            presentedSheet = FoodItemLogDetailsView(foodItemLog: foodItemLog).asAny
          } label: {
            Text("Edit Meal")
              .bold()
              .horizontallyCentered()
              .frame(minHeight: 60)
          }
          Divider()
        }
      }

      LabeledContent("Serving Size", value: foodItem.displayServing)
        .frame(minHeight: 60)

      if mode == .editAndView {
        Divider()

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
                    servingQuantity: foodItem.servingQuantity
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
              servingQuantity: foodItem.servingQuantity
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
    }
    .padding(.horizontal)
    .cardContainer(includePadding: false)
  }

  var accuracySection: some View {
    Group {
      if hasMarkedAsInaccurate {
        Button("Report Submitted", systemImage: "checkmark.circle.fill", role: .destructive) { }
          .disabled(true)
      } else {
        Button("Report an Issue", systemImage: "exclamationmark.triangle.fill", role: .destructive) {
          presentedSheet = FoodItemIssueReportView(foodItem: foodItem) {
            hasMarkedAsInaccurate = true
          }.asAny
        }
      }
    }
    .bold()
    .cardContainer()
  }

  var foodItemMenu: some View {
    Menu("Options", systemImage: "ellipsis.circle") {
      if !hasMarkedAsInaccurate {
        // TODO: Only show this when the FoodItem is not AI generated.
        Button("Report an Issue", systemImage: "exclamationmark.triangle") {
          presentedSheet = FoodItemIssueReportView(foodItem: foodItem) {
            hasMarkedAsInaccurate = true
          }.asAny
        }
      }

      if let existingFoodItemLog {
        Divider()
        
        if existingFoodItemLog.hasSingleServing {
          Button("Delete Log", systemSymbol: .trash, role: .destructive) {
            Task {
              do {
                try await nutritionViewModel.delete(
                  modelContext: modelContext,
                  foodItemLogs: [existingFoodItemLog]
                )
                dismiss()
              } catch {
                self.error = error
              }
            }
          }
          .tint(.red)
        } else {
          // Delete individual serving from meal with multiple items
          Button("Delete from Meal", systemSymbol: .trash, role: .destructive) {
            guard let foodItemServing else { return }

            Task {
              do {
                try await nutritionViewModel.delete(
                  modelContext: modelContext,
                  foodItemServing: foodItemServing
                )
                dismiss()
              } catch {
                self.error = error
              }
            }
          }
          .tint(.red)
        }
      }
    }
  }
}

private extension FoodItemDetailsView {

  // MARK: - Mass/Servings Conversion

  static func calculateMassFromServings(servings: Double, servingQuantity: BloomModel.FoodItem.Quantity?) -> Double {
    guard let servingQuantity else { return 0.0 }
    return servings * servingQuantity.value
  }

  static func calculateServingsFromMass(mass: Double, servingQuantity: BloomModel.FoodItem.Quantity?) -> Double {
    guard let servingQuantity, servingQuantity.value > 0 else { return 0.0 }
    return mass / servingQuantity.value
  }

  var massUnit: String {
    foodItem.servingQuantity?.unit ?? "g"
  }

  var canShowMassInput: Bool {
    foodItem.servingQuantity != nil
  }
}

private extension FoodItemDetailsView {

  var foodItemServing: FoodItemServing? {
    existingFoodItemLog?.serving(for: foodItem.id.value)
  }

  var canSave: Bool {
    guard let existingFoodItemLog else { return true }

    return foodItemServing?.numberOfServings != numberOfServings ||
    existingFoodItemLog.date != date ||
    existingFoodItemLog.meal != meal
  }

  func save() async throws {
    if let existingFoodItemLog {
      let isSingleServing = existingFoodItemLog.hasSingleServing

      try await nutritionViewModel.update(
        modelContext: modelContext,
        foodItemLog: existingFoodItemLog,
        foodItemID: foodItem.id.value,
        numberOfServings: numberOfServings,
        dateMeal: isSingleServing ? (date, meal) : nil
      )
    } else {
      try await nutritionViewModel.log(
        modelContext: modelContext,
        foodItem: foodItem,
        date: date,
        meal: meal,
        numberOfServings: numberOfServings
      )

      // Donate intent for Siri suggestions
      await IntentDonator.donateMealLog(
        foodItemServings: [FoodItemServingAmount(serving: numberOfServings, foodItem: foodItem)],
        meal: meal,
        numberOfServings: numberOfServings
      )
    }

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview("No Existing Log") {
  PreviewEnvironment {
    FoodItemDetailsView(
      foodItem: .Preview.ritzCrackers,
      existingFoodItemLog: nil
    )
  }
}

#Preview("Single FoodItemServing") {
  PreviewEnvironment {
    FoodItemDetailsView(
      foodItem: .Preview.ritzCrackers,
      existingFoodItemLog: FoodItemLog(
        id: "789",
        name: "Cracker Snack",
        date: .now,
        meal: .breakfast,
        numberOfServings: 1,
        imageData: UIImage(named: "MockProductImage")?.pngData(),
        foodItemServings: [
          FoodItemServing(
            numberOfServings: 1,
            foodItem: .Preview.ritzCrackers
          )
        ]
      )
    )
  }
}

#Preview("Multiple FoodItemServings") {
  PreviewEnvironment {
    FoodItemDetailsView(
      foodItem: .Preview.ritzCrackers,
      existingFoodItemLog: FoodItemLog(
        id: "789",
        name: "Cracker Snack",
        date: .now,
        meal: .breakfast,
        numberOfServings: 1,
        imageData: UIImage(named: "CheeseAndCrackers")?.pngData(),
        foodItemServings: [
          FoodItemServing(
            numberOfServings: 1,
            foodItem: .Preview.ritzCrackers
          ),
          FoodItemServing(
            numberOfServings: 2,
            foodItem: .Preview.shreddedCheddar
          )
        ]
      )
    )
  }
}
