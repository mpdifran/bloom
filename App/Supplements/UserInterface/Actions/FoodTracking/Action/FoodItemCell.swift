//
//  FoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI
import AppUI
import BloomModel
import DataContainer

struct FoodItemCell: View {
    let food: FoodItem

    private let nutritionViewModel = NutritionTrackingViewModel.shared
    private let foodItemLogModelActor = FoodItemLogModelActor(modelContainer: ContainerHolder.shared.container)

    @State private var saveComplete = false
    @State private var existingFoodLog: FoodItemLogDTO?
    @State private var error: Error?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    if food.isVerified {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.white, .mutedGreen)
                        Text("Verified")
                            .foregroundStyle(.mutedGreen)
                            .bold()
                    }

                    Text(food.brandName ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .bold()
                }
                .font(.caption)

                HStack(alignment: .firstTextBaseline) {
                    Text(food.name)
                    if let flavour = food.flavour {
                        Text(flavour)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .bold()

                if
                    let serving = food.servingName,
                    let servingQuantity = food.servingQuantity
                {
                    Text("\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
                        .font(.caption)
                }
            }

            Spacer()

            if let calories = food.calories?.value {
                VStack(spacing: 0) {
                    Text("\(calories.format())")
                        .bold()
                        .font(.title2)
                        .foregroundStyle(.tint)
                    Text("cals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .fontDesign(.rounded)
            }

            Button {
                guard existingFoodLog == nil else { return }

                Task { await quickLogFood() }
            } label: {
                if existingFoodLog == nil {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.tint, .tint.tertiary)
                        .font(.largeTitle)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, .tint)
                        .font(.largeTitle)
                }
            }
            .sensoryFeedback(.success, trigger: saveComplete)
            .disabled(existingFoodLog != nil)
        }
        .cardContainer(fill: .background.secondary)
        .alert(error: $error)
        .onChange(of: nutritionViewModel.suggestedMeal) { _, _ in
            Task { await checkForExistingFoodLog() }
        }
    }
}

private extension FoodItemCell {

    func quickLogFood() async {
        do {
            try nutritionViewModel.log(
                foodItem: food,
                meal: nutritionViewModel.suggestedMeal,
                numberOfServings: 1
            )
            await checkForExistingFoodLog()
            saveComplete.toggle()
            SoundPlayer.playLogHealthData()
        } catch {
            self.error = error
        }
    }

    func checkForExistingFoodLog() async {
        do {
            existingFoodLog = try await foodItemLogModelActor.fetchLog(
                for: .now,
                meal: nutritionViewModel.suggestedMeal,
                foodItemID: food.id.value
            )
        } catch {
            print(error)
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            FoodItemCell(
                food: .init(
                    id: .init(),
                    name: "Yogurt",
                    brandName: "Activia",
                    flavour: "Rhubarb",
                    calories: .init(value: 91, unit: "kcal"),
                    protein: .init(value: 3.9, unit: "g"),
                    carbohydrates: .init(value: 12, unit: "g"),
                    fat: .init(value: 2.8, unit: "g"),
                    servingName: "1 package",
                    servingQuantity: .init(value: 43, unit: "g"),
                    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
                    isVerified: false
                )
            )
            FoodItemCell(
                food: .init(
                    id: .init(),
                    name: "Crackers",
                    brandName: "Ritz",
                    flavour: "Low Sodium",
                    calories: .init(value: 91, unit: "kcal"),
                    protein: .init(value: 3.9, unit: "g"),
                    carbohydrates: .init(value: 12, unit: "g"),
                    fat: .init(value: 2.8, unit: "g"),
                    servingName: "1 package",
                    servingQuantity: .init(value: 43, unit: "g"),
                    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
                    isVerified: true
                )
            )
        }
        .padding()
    }
}
