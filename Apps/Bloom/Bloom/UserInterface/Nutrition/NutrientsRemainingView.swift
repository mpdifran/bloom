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

  @ObservedObject private var viewModel: NutrientsRemainingViewModel

  init(date: Date) {
    _viewModel = ObservedObject(
      wrappedValue: NutrientsRemainingViewModel(date: date)
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleView

      cardView
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
          Text(viewModel.calorieString)
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

        HStack {
          NutrientLabel(
            value: viewModel.proteinValue,
            target: viewModel.proteinTarget,
            displayAmount: viewModel.proteinString,
            label: "Protein"
          )
          .frame(width: 80)
          .tint(.mutedTeal)
          NutrientLabel(
            value: viewModel.fatsValue,
            target: viewModel.remainingTarget,
            displayAmount: viewModel.fatsString,
            label: "Fats"
          )
          .frame(width: 50)
          .tint(.mutedOrange)
          NutrientLabel(
            value: viewModel.carbsValue,
            target: viewModel.remainingTarget,
            displayAmount: viewModel.carbsString,
            label: "Carbs"
          )
          .frame(width: 50)
          .tint(.mutedPurple)
        }
      }

      DisclosureIndicator()
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
  }
}
