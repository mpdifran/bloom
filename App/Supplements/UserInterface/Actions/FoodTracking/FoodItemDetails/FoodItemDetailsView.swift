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
            self._meal = State(initialValue: existingFoodItemLog.meal)
        } else {
            self._numberOfServings = State(initialValue: 1)
            self._meal = State(initialValue: .breakfast)
        }
    }

    @State private var numberOfServings: Double
    @State private var meal: FoodItemLog.Meal = .breakfast
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
            }
            .shelf {
                if isFocused {
                    ProminentButton("Done") {
                        isFocused = false
                    }
                } else {
                    ProminentButton("Log") {
                        Task {
                            do {
                                try await save()

                                saveComplete.toggle()
                                SoundPlayer.playLogHealthData()
                                dismiss()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .sensoryFeedback(.success, trigger: saveComplete)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .alert(error: $error)
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

    var macrosSection: some View {
        VStack {
            FoodItemMacroDistribution(
                protein: foodItem.protein?.value,
                carbohydrates: foodItem.carbohydrates?.value,
                fat: foodItem.fat?.value
            )
        }
        .cardContainer(fill: .background.secondary)
    }

    var editSection: some View {
        VStack(spacing: 0) {
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

            Divider()

            LabeledContent("Meal") {
                Picker(meal.name, selection: $meal) {
                    ForEach(FoodItemLog.Meal.allCases) { meal in
                        Text(meal.name)
                            .tag(meal)
                    }
                }
            }
            .frame(minHeight: 60)
        }
        .padding(.horizontal)
        .cardContainer(fill: .background.secondary, includePadding: false)
    }

    var accuracySection: some View {
        Button("Mark as Inaccurate") {

        }
        .foregroundStyle(.mutedRed)
        .cardContainer(fill: .background.secondary)
    }
}

private extension FoodItemDetailsView {

    func save() async throws {
        try modelContext.transaction {
            if let existingFoodItemLog {
                existingFoodItemLog.numberOfServings = numberOfServings
                existingFoodItemLog.meal = meal

            } else {
                let dbFoodItem: FoodItemRecord
                if let existingFoodItem = try modelContext.fetchFoodItem(for: foodItem.id.value) {
                    dbFoodItem = existingFoodItem
                } else {
                    dbFoodItem = FoodItemRecord(foodItem: foodItem)
                    modelContext.insert(dbFoodItem)
                }

                let foodItemLog = FoodItemLog(
                    id: UUID().uuidString,
                    date: .now, // TODO: this date needs to be computed based on the selected date + meal.
                    meal: meal,
                    numberOfServings: numberOfServings,
                    foodItem: dbFoodItem
                )

                modelContext.insert(foodItemLog)
            }
        }
    }
}

#Preview {
    FoodItemDetailsView(
        foodItem: .init(
            id: .init("1234"),
            name: "Crackers",
            brandName: "Ritz",
            flavour: "Low Sodium",
            calories: .init(value: 100, unit: "kcal"),
            protein: .init(value: 1, unit: "g"),
            carbohydrates: .init(value: 13, unit: "g"),
            fat: .init(value: 4.5, unit: "g"),
            servingName: "6 crackers",
            servingQuantity: .init(value: 20, unit: "g"),
            ingredients: nil,
            isVerified: true
        ),
        existingFoodItemLog: nil
    )
}
