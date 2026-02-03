//
//  FoodServingView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import BloomFoundation
import WatchKit

struct FoodServingView: View {
  let food: WatchFoodItem
  let meal: WatchMeal
  let performDismiss: (() -> Void)?

  @State private var selectedIndex: Double
  @State private var isSaving = false
  @State private var showingSaveConfirmation = false
  @FocusState private var isFocused: Bool

  // Serving options with fractions
  private static let servingOptions: [Double] = {
    var options: [Double] = []
    for whole in 0...10 {
      let base = Double(whole)
      options.append(contentsOf: [
        base + 0.25,
        base + 0.33,
        base + 0.5,
        base + 0.66,
        base + 0.75,
        base + 1.0
      ])
    }
    return options.filter { $0 >= 0.25 }.sorted().uniqued()
  }()

  private var servings: Double {
    let index = min(max(0, Int(selectedIndex)), Self.servingOptions.count - 1)
    return Self.servingOptions[index]
  }

  private var calories: Int {
    Int(food.calories * servings)
  }

  init(food: WatchFoodItem, meal: WatchMeal, performDismiss: (() -> Void)? = nil) {
    self.food = food
    self.meal = meal
    self.performDismiss = performDismiss
    // Default to index of 1.0 serving
    let defaultIndex = Self.servingOptions.firstIndex(of: 1.0) ?? 5
    _selectedIndex = State(initialValue: Double(defaultIndex))
  }

  var body: some View {
    VStack {
      // Food name
      Text(food.name)
        .font(.title3)
        .bold()
        .lineLimit(2)
        .multilineTextAlignment(.center)

      Spacer()

      HStack {
        Spacer()

        VStack {
          Text("\(calories)")
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.tint)
          Text("cals")
            .foregroundStyle(.secondary)
        }
        Spacer()

        Text("•")

        Spacer()

        VStack {
          Text(formattedServings)
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.tint)
            .focusable()
            .focused($isFocused)
            .digitalCrownRotation(
              $selectedIndex,
              from: 0.0,
              through: Double(Self.servingOptions.count - 1),
              by: 1.0,
              sensitivity: .low
            )
          Text("servings")
            .foregroundStyle(.secondary)
          Text(food.servingName)
            .font(.footnote)
            .foregroundStyle(.tertiary)
        }

        Spacer()
      }
      .horizontallyCentered()

      Spacer()

      // Log button
      Button(action: save) {
        Text("Log")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(isSaving)
      .horizontallyCentered()
    }
    .navigationTitle(meal.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .padding(.bottom)
    .ignoresSafeArea(edges: .bottom)
    .frame(maxWidth: .infinity)
    .background(.black)
    .tint(.mutedGreen)
    .onAppear { isFocused = true }
    .overlay {
      if isSaving {
        ZStack {
          Color.black.opacity(0.7)
          ProgressView()
        }
        .ignoresSafeArea()
      } else if showingSaveConfirmation {
        ZStack {
          Color.black.opacity(0.7)
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 50))
            .foregroundStyle(.green)
        }
        .ignoresSafeArea()
      }
    }
  }

  private var formattedServings: String {
    let fraction = servings.truncatingRemainder(dividingBy: 1)
    let whole = Int(servings)

    // Use Unicode fractions for exact quarters and halves, decimals for thirds
    let fractionString: String
    if abs(fraction) < 0.01 {
      fractionString = ""
    } else {
      // Fallback to decimal for any other fraction
      return String(format: "%.2f", servings)
    }

    if whole == 0 {
      return fractionString.isEmpty ? "1" : fractionString
    } else if fractionString.isEmpty {
      return "\(whole)"
    } else {
      return "\(whole)\(fractionString)"
    }
  }

  private func save() {
    guard !isSaving else { return }

    isSaving = true

    Task {
      let success = await PendingFoodLogManager.shared.log(
        foodItemID: food.id,
        meal: meal.rawValue,
        numberOfServings: servings
      )

      isSaving = false

      if success {
        WKInterfaceDevice.current().play(.success)
        showingSaveConfirmation = true
        try? await Task.sleep(for: .seconds(1))
        performDismiss?()
      } else {
        WKInterfaceDevice.current().play(.failure)
      }
    }
  }
}

// MARK: - Array Extension

private extension Array where Element: Hashable {
  func uniqued() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

#Preview {
  NavigationStack {
    FoodServingView(
      food: WatchFoodItem(
        id: "1",
        name: "Chicken Breast",
        brandName: nil,
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        servingName: "100g"
      ),
      meal: .lunch
    )
  }
}
