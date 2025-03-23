//
//  NutrientsRemainingView.swift
//  Bloom
//
//  Created by Zach Radford on 2025-01-30.
//

import AppUI
import SwiftUI
import DataContainer

struct NutrientsRemainingView: View {

  @StateObject private var viewModel = NutrientsRemainingViewModel()
  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleView

      cardView
    }
    .task {
      viewModel.observeChanges(for: .duringDay(.now))
    }
    .onChange(of: nutritionViewModel.date) { _, newValue in
      viewModel.observeChanges(for: .duringDay(newValue))
    }
  }
}

private extension NutrientsRemainingView {
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
          Text(viewModel.caloriesString)
            .font(
              .system(
                .title3,
                design: .rounded,
                weight: .black
              )
            )
            .foregroundStyle((Double(viewModel.caloriesString) ?? 0) < 0 ? .mutedRed : .primary)

          Text("Calories")
            .bold()
            .foregroundStyle(.secondary)
            .font(.caption)
        }

        Spacer()

        HStack {
          Group {
            NutrientLabel(
              value: viewModel.proteinValue,
              target: viewModel.proteinTarget,
              displayAmount: viewModel.proteinString,
              label: "Protein"
            )
            .tint(.protein)

            NutrientLabel(
              value: viewModel.carbsValue,
              target: viewModel.carbsTarget,
              displayAmount: viewModel.carbsString,
              label: "Carbs"
            )
            .tint(.carbohydrates)

            NutrientLabel(
              value: viewModel.fatsValue,
              target: viewModel.fatsTarget,
              displayAmount: viewModel.fatsString,
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
          target: target
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
