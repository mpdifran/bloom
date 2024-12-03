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

  @State private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var numberOfServings: Double
  @State private var date: Date
  @State private var meal: FoodItemLog.Meal
  @State private var showDatePicker = false
  @State private var saveComplete = false
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
          Menu("Options", systemImage: "ellipsis.circle") {
            Button("Mark as Inaccurate", systemImage: "exclamationmark.triangle") {
              Task { await markAsInaccurate() }
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
      .shelf {
        if isFocused {
          ProminentButton("Done") {
            isFocused = false
          }
        } else {
          ProminentButton(existingFoodItemLog == nil ? "Log" : "Save") {
            Task {
              do {
                try await save()
                dismiss()
              } catch {
                self.error = error
              }
            }
          }
          .disabled(!canSave)
          .sensoryFeedback(.success, trigger: saveComplete)
        }
      }
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
      .animation(.easeInOut, value: numberOfServings)
      .alert(error: $error)
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
            Text("\(nutritionViewModel.date, formatter: DateFormatter.justRelativeDateMedium)")
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption)
          }
          .padding()
        }
        .popover(isPresented: $showDatePicker) {
          DatePicker(selection: $nutritionViewModel.date, displayedComponents: .date) {
            Text("\(nutritionViewModel.date, formatter: DateFormatter.justRelativeDateMedium)")
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

      Divider()

      LabeledContent("Serving Size", value: foodItem.displayServing)
        .frame(minHeight: 60)
    }
    .padding(.horizontal)
    .cardContainer(fill: .background.secondary, includePadding: false)
  }

  var accuracySection: some View {
    Button("Mark as Inaccurate", systemImage: "exclamationmark.triangle.fill") {
      Task {
        await markAsInaccurate()
      }
    }
    .bold()
    .cardContainer(fill: .background.secondary)
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
        meal: meal,
        numberOfServings: numberOfServings
      )
    }

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }

  func markAsInaccurate() async {
    // TODO: Implement
  }
}

#Preview {
  FoodItemDetailsView(
    foodItem: .Preview.ritzCrackers,
    existingFoodItemLog: nil
  )
}
