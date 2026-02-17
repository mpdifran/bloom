//
//  NutrientsWidgetView.swift
//  Bloom
//
//  Created by Zach Radford on 2025-01-30.
//

import AppUI
import SwiftUI
import DataContainer
import BloomFoundation
import CoreHealth
import SwiftData

struct NutrientsWidgetView: View {

  @StateObject private var viewModel = NutrientsWidgetViewModel()

  @Query private var foodItemLogs: [FoodItemLog]

  init(date: Date = .now) {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.endOfDay(for: date)

    self._foodItemLogs = Query(
      filter: #Predicate<FoodItemLog> { log in
        log.date >= startOfDay &&
        log.date <= endOfDay
      },
      sort: \FoodItemLog.date,
      order: .forward
    )
  }

  // MARK: - Computed Macros from Food Items

  private var caloriesValue: Double {
    foodItemLogs.totalCalories
  }

  private var proteinValue: Double {
    foodItemLogs.totalProtein
  }

  private var carbsValue: Double {
    foodItemLogs.totalCarbs
  }

  private var fatsValue: Double {
    foodItemLogs.totalFat
  }

  private var caloriesString: String {
    caloriesValue.format()
  }

  private var proteinString: String {
    "\(proteinValue.format()) g"
  }

  private var carbsString: String {
    "\(carbsValue.format()) g"
  }

  private var fatsString: String {
    "\(fatsValue.format()) g"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleView

      cardView
    }
    .task {
      await viewModel.fetchGoals()
    }
  }
}

private extension NutrientsWidgetView {
  var titleView: some View {
    Text(viewModel.title)
      .font(
        .system(
          .headline,
          design: .rounded,
          weight: .black
        )
      )
  }

  var cardView: some View {
    HStack {
      HStack(alignment: .bottom) {
        VStack(alignment: .leading) {
          Text(caloriesString)
            .font(
              .system(
                .title3,
                design: .rounded,
                weight: .black
              )
            )

          Text("Calories")
            .bold()
            .foregroundStyle(.secondary)
            .font(.caption)
        }

        Spacer()

        HStack(alignment: .bottom) {
          Group {
            NutrientLabel(
              value: proteinValue,
              target: viewModel.proteinTarget,
              displayAmount: proteinString,
              label: "Protein"
            )
            .tint(.protein)

            NutrientLabel(
              value: carbsValue,
              target: viewModel.carbsTarget,
              displayAmount: carbsString,
              label: "Carbs"
            )
            .tint(.carbohydrates)

            NutrientLabel(
              value: fatsValue,
              target: viewModel.fatsTarget,
              displayAmount: fatsString,
              label: "Fats"
            )
            .tint(.fat)
          }
          .fixedSize(horizontal: true, vertical: false)
        }
      }

      // TODO: Zach - add back when there is navigation
      // DisclosureIndicator()
    }
    .cardContainer()
  }
}

private struct NutrientLabel: View {
  let value: Double
  let target: Double?
  let displayAmount: String
  let label: String

  var body: some View {
    VStack(alignment: .leading) {
      if let target {
        ProgressBar(
          value: value,
          target: target,
          measurementStyle: .minimum
        )
        .foregroundStyle(.tint)
      }

      Group {
        Text(displayAmount)
          .font(
            .system(
              .title3,
              design: .rounded,
              weight: .black
            )
          )
          .foregroundStyle(.tint)

        Text(label)
          .bold()
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      .padding(.trailing, 8)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        NutrientsWidgetView()
      }
      .padding()
    }
    .groupedBackground()
  }
}
