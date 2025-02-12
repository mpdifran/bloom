//
//  FoodItemDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-21.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct FoodItemDetailsView: View {
  let foodItem: BloomModel.FoodItem
  let existingFoodItemLog: FoodItemLog?

  init(
    foodItem: BloomModel.FoodItem,
    existingFoodItemLog: FoodItemLog?
  ) {
    self.foodItem = foodItem
    self.existingFoodItemLog = existingFoodItemLog

    if let existingFoodItemLog {
      self._numberOfServings = State(initialValue: existingFoodItemLog.numberOfServings)
      self._date = State(initialValue: existingFoodItemLog.date)
      self._meal = State(initialValue: existingFoodItemLog.meal)
    } else {
      self._numberOfServings = State(initialValue: 1)
      self._date = State(initialValue: NutritionTrackingViewModel.shared.date)
      self._meal = State(initialValue: NutritionTrackingViewModel.shared.suggestedMeal)
    }
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

          accuracySection
        }
        .padding()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
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
        } else {
          AsyncButton {
            try await save()
            dismiss()
          } label: {
            Text(existingFoodItemLog == nil ? "Log" : "Save")
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
      .sheet($presentedSheet)
      .alert(error: $error)
      .alert(alertDetails: $alertDetails)
      .tint(.mutedGreen)
    }
  }
}

private extension FoodItemDetailsView {

  var nameSection: some View {
    VStack {
      HStack {
        VStack(alignment: .leading) {
          Group {
            if let brandName = foodItem.brandName {
              Text(brandName) + Text(" ") + Text(foodItem.name)
            } else {
              Text(foodItem.name)
            }
          }
          .font(.title)
          .bold()

          if let flavour = foodItem.flavour {
            Text(flavour)
              .font(.body)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()

        if foodItem.isVerified {
          HStack(spacing: 2) {
            Image(systemName: "checkmark.shield.fill")
              .foregroundStyle(.white, .mutedGreen)
            Text("Verified")
              .foregroundStyle(.mutedGreen)
              .bold()
          }
        }
      }
      .padding(.horizontal)
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
        Text("cal")
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
    .cardContainer(fill: .background.secondary)
  }

  var editSection: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Spacer()

        Button {
          showDatePicker.toggle()
        } label: {
          HStack(spacing: 2) {
            Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
            Image(systemName: "chevron.up.chevron.down")
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

      Divider()

      LabeledContent("Serving Size", value: foodItem.displayServing)
        .frame(minHeight: 60)

      Divider()

      LabeledContent("Number of Servings") {
        TextField("", value: $numberOfServings, formatter: NumberFormatter.oneDecimalPlace)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 70)
          .fontDesign(.rounded)
          .keyboardType(.decimalPad)
          .focused($isFocused)
          .selectAllTextOnBeginEditing()
      }
      .frame(minHeight: 60)
    }
    .padding(.horizontal)
    .cardContainer(fill: .background.secondary, includePadding: false)
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
    .cardContainer(fill: .background.secondary)
  }

  var foodItemMenu: some View {
    Menu("Options", systemImage: "ellipsis.circle") {
      if !hasMarkedAsInaccurate {
        Button("Report an Issue", systemImage: "exclamationmark.triangle") {
          presentedSheet = FoodItemIssueReportView(foodItem: foodItem) {
            hasMarkedAsInaccurate = true
          }.asAny
        }
      }

      Divider()
      Button("Delete Log", systemImage: "trash", role: .destructive) {
        guard let log = existingFoodItemLog else { return }

        Task {
          do {
            try await nutritionViewModel.delete(foodItemLogs: [log])
            dismiss()
          } catch {
            self.error = error
          }
        }
      }
    }
  }
}

private extension FoodItemDetailsView {

  var canSave: Bool {
    guard let existingFoodItemLog else { return true }

    return existingFoodItemLog.numberOfServings != numberOfServings ||
    existingFoodItemLog.date != date ||
    existingFoodItemLog.meal != meal
  }

  func save() async throws {
    if let existingFoodItemLog {
      try await nutritionViewModel.update(
        foodItem: existingFoodItemLog,
        numberOfServings: numberOfServings,
        date: date,
        meal: meal
      )
    } else {
      try await nutritionViewModel.log(
        foodItem: foodItem,
        date: date,
        meal: meal,
        numberOfServings: numberOfServings
      )
    }

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  FoodItemDetailsView(
    foodItem: .Preview.ritzCrackers,
    existingFoodItemLog: nil
  )
}
