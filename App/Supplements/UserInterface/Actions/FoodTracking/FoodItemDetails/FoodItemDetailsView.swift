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

    @State private var numberOfServings: Double = 1.5
    @State private var meal: FoodLoggingActionCardView.ViewModel.Meal = .breakfast

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
                ProminentButton("Log") {

                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
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
                    .selectAllTextOnBeginEditing()
            }
            .frame(minHeight: 60)

            Divider()

            LabeledContent("Meal") {
                Picker(meal.name, selection: $meal) {
                    ForEach(FoodLoggingActionCardView.ViewModel.Meal.allCases) { meal in
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
        )
    )
}
