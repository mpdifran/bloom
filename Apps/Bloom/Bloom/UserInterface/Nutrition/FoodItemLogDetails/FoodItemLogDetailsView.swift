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
          Button("Done") {
            dismiss()
          }
          .bold()
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
        Text("cal")
          .foregroundStyle(.secondary)
          .font(.title3)
      }
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .contentTransition(.numericText(value: foodItemLog.totalCalories))

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

  var editSection: some View {
    VStack(spacing: 0) {
      dateMealPickers

      Divider()

      Divider()

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
      .frame(minHeight: 60)
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
                  delete(serving)
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
                delete(serving)
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
        try save()
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

  func save() throws {
    try modelContext.update(
      foodItemLog: foodItemLog,
      numberOfServings: numberOfServings,
      foodItemNumberOfServings: foodItemNumberOfServings,
      date: date,
      meal: meal
    )

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }

  func delete(_ foodItemServing: FoodItemServing) {
    do {
      try modelContext.delete(foodItemServing: foodItemServing)
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
