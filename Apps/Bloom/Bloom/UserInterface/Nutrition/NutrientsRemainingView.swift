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
    Text("Nutrients remaining")
      .font(
        .system(
          .headline,
          design: .rounded,
          weight: .black
        )
      )
  }

  var cardView: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading) {
        Text(viewModel.calorieTotal.format())
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
        NutrientLabel(value: viewModel.proteinTotal, label: "Protein")
        NutrientLabel(value: viewModel.fatsTotal, label: "Fats")
        NutrientLabel(value: viewModel.carbsTotal, label: "Carbs")
      }

      DisclosureIndicator()
    }
    .cardContainer()
  }
}

private struct NutrientLabel: View {
  let value: Double
  let label: String

  var body: some View {
    VStack(alignment: .leading) {
      ProgressBar(
        value: value,
        target: 125
      )

      Text(value.format())

      Text(label)
        .bold()
        .foregroundStyle(.secondary)
        .font(.caption)
    }
  }
}
