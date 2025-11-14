//
//  MealHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-13.
//

import SwiftUI
import CoreHealth

struct MealHeaderView: View {
  let mealName: String
  let totalCalories: Double
  let totalProtein: Double
  let totalCarbs: Double
  let totalFat: Double
  let onLogTapped: (() -> Void)?

  init(
    mealName: String,
    totalCalories: Double,
    totalProtein: Double,
    totalCarbs: Double,
    totalFat: Double,
    onLogTapped: (() -> Void)?
  ) {
    self.mealName = mealName
    self.totalCalories = totalCalories
    self.totalProtein = totalProtein
    self.totalCarbs = totalCarbs
    self.totalFat = totalFat
    self.onLogTapped = onLogTapped
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 12) {
          Text(mealName)
            .font(
              .system(
                .headline,
                design: .rounded,
                weight: .black
              )
            )

          if totalProtein > 0 || totalCarbs > 0 || totalFat > 0 {
            MacroDistributionBar(
              proteinGrams: totalProtein,
              carbsGrams: totalCarbs,
              fatGrams: totalFat
            )
            .frame(width: 60)
          }
        }

        Text("\(totalCalories.format()) Cals • \(totalProtein.format()) g Protein •  \(totalCarbs.format()) g Carbs • \(totalFat.format()) g Fats")
          .font(.caption)
          .foregroundStyle(.secondary)
          .bold()
      }

      Spacer()

      if let onLogTapped {
        Button {
          onLogTapped()
        } label: {
          Label("Add", systemSymbol: .plus)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundStyle(.tint)
            .font(.subheadline)
            .fontDesign(.rounded)
            .bold()
            .background(.background)
            .clipShape(Capsule())
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MealHeaderView(
        mealName: "Breakfast",
        totalCalories: 300,
        totalProtein: 38,
        totalCarbs: 126,
        totalFat: 14,
        onLogTapped: nil
      )
    }
  }
}
