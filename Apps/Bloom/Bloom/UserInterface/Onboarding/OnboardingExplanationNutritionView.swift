//
//  OnboardingExplanationNutritionView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-13.
//

import SwiftUI
import AppUI
import BloomUI
import BloomModel
import BloomFoundation
import DataContainer
import TelemetryDeck

struct OnboardingExplanationNutritionView: View {
  let onContinue: () -> Void

  @State private var index = 0

  var body: some View {
    BloomScrollView(padding: .bottom) {
      ZStack {
        Image(.afternoonScenery)
          .resizable()
          .scaledToFit()
          .parallaxOverscroll()
          .zStackAlignment(.top)

        VStack {
          BudImage(.budSuperhero, dimension: 180)
          helloSection
          nutritionSection
        }
        .padding(.top, 160)
      }
    }
    .removeScrollEdgeEffect(shouldHide: true)
    .ignoresSafeArea(.all, edges: .top)
    .animation(.bouncy, value: index)
    .sensoryFeedback(.impact, trigger: index)
    .shelf {
      Button {
        index += 1
        onContinue()
      } label: {
        Text("Delicious!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      TelemetryDeck.signal("OB Nutrition Explanation")
    }
  }
}

private extension OnboardingExplanationNutritionView {

  var helloSection: some View {
    Text("Track what you eat!")
      .font(.title)
      .bold()
      .fontDesign(.rounded)
      .horizontalAlignment(.leading)
      .padding(.horizontal)
  }

  var nutritionSection: some View {
    VStack(alignment: .leading) {
      Text("Learn patterns in your eating habits. Scan barcodes for faster logging.")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .transition(.blurReplace)
        .foregroundStyle(.secondary)

      if index >= 1 {
        MealHeaderView(
          mealName: "Breakfast",
          totalCalories: 400,
          totalProtein: 25,
          totalCarbs: 90,
          totalFat: 30,
          onLogTapped: nil
        )
        .transition(.blurReplace)
      }

      if index >= 2 {
        FoodItemLogCell(foodItemLog: .scrambledEggs) { _ in

        } showMealDetails: { _ in

        }
        .transition(.scale)
      }

      if index >= 3 {
        FoodItemLogCell(foodItemLog: .toast) { _ in

        } showMealDetails: { _ in

        }
        .transition(.scale)
      }
    }
    .padding(.horizontal)
    .horizontalAlignment(.leading)
    .fixedSize(horizontal: false, vertical: true)
    .task {
      await advanceIndex()
    }
  }
}

private extension OnboardingExplanationNutritionView {

  func advanceIndex() async {
    await Delay(1000)
    index += 1
    await Delay(200)
    index += 1
    await Delay(100)
    index += 1
  }
}

private extension FoodItemLog {

  @MainActor
  static let scrambledEggs = FoodItemLog(
    id: "1234",
    name: "Scrambled Eggs",
    date: .now,
    meal: .breakfast,
    numberOfServings: 1,
    imageData: nil,
    foodItemServings: [
      FoodItemServing(
        id: "1234",
        numberOfServings: 1,
        foodItem: .scrambledEggs
      )
    ]
  )

  @MainActor
  static let toast = FoodItemLog(
    id: "5678",
    name: "Toast",
    date: .now,
    meal: .breakfast,
    numberOfServings: 2,
    imageData: nil,
    foodItemServings: [
      FoodItemServing(
        id: "5678",
        numberOfServings: 2,
        foodItem: .toast
      )
    ]
  )
}

private extension FoodItemRecord {

  @MainActor
  static let scrambledEggs = FoodItemRecord(
    id: "1234",
    name: "Scrambled Eggs",
    brandName: "Eggland's Best",
    flavour: "",
    rawCountry: "usa",
    calories: 200,
    protein: 15,
    carbohydrates: 10,
    fat: 30,
    saturatedFat: nil,
    transFat: nil,
    polyunsaturatedFat: nil,
    monounsaturatedFat: nil,
    fiber: nil,
    sugar: nil,
    cholesterol: nil,
    sodium: nil,
    calcium: nil,
    iron: nil,
    potassium: nil,
    magnesium: nil,
    zinc: nil,
    vitaminA: nil,
    vitaminB6: nil,
    vitaminB12: nil,
    vitaminC: nil,
    vitaminD: nil,
    vitaminE: nil,
    servingName: "1 egg",
    servingUnitString: "g",
    servingValue: 40,
    ingredients: nil,
    category: nil,
    isVerified: true
  )

  @MainActor
  static let toast = FoodItemRecord(
    id: "5678",
    name: "Toast",
    brandName: "Wonder Bread",
    flavour: "",
    rawCountry: "usa",
    calories: 100,
    protein: 5,
    carbohydrates: 40,
    fat: 0,
    saturatedFat: nil,
    transFat: nil,
    polyunsaturatedFat: nil,
    monounsaturatedFat: nil,
    fiber: nil,
    sugar: nil,
    cholesterol: nil,
    sodium: nil,
    calcium: nil,
    iron: nil,
    potassium: nil,
    magnesium: nil,
    zinc: nil,
    vitaminA: nil,
    vitaminB6: nil,
    vitaminB12: nil,
    vitaminC: nil,
    vitaminD: nil,
    vitaminE: nil,
    servingName: "1 egg",
    servingUnitString: "g",
    servingValue: 40,
    ingredients: nil,
    category: nil,
    isVerified: true
  )
}

#Preview {
  PreviewEnvironment {
    OnboardingExplanationNutritionView() { }
  }
}
