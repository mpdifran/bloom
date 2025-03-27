//
//  MealRecordCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import DataContainer

private extension CGFloat {
  static let imageHeight: CGFloat = 160
}

struct MealRecordCell: View {
  let mealRecord: MealRecord

  @State private var saveComplete = false
  @State private var hasLoggedThisMeal = false

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @Environment(\.modelContext) private var modelContext

  var body: some View {
    VStack {
      Group {
        if let imageData = mealRecord.imageData, let image = UIImage(data: imageData) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: .imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
          RoundedRectangle(cornerRadius: 18)
            .fill(.fill)
            .frame(height: .imageHeight)
            .overlay {
              Image(systemSymbol: .photoFillOnRectangleFill)
                .font(.largeTitle)
                .foregroundStyle(.fill.secondary)
            }
        }
      }
      .padding(.horizontal, 8)
      .padding(.top, 8)

      HStack {
        VStack(alignment: .leading) {
          Text(mealRecord.name)
            .font(.body)
            .bold()
            .fontDesign(.rounded)

          Text(macrosDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
            .fontDesign(.rounded)
        }
        .lineLimit(2)

        Spacer()

        Text(caloriesDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .bold()
          .fontDesign(.rounded)

        AsyncButton {
          guard !hasLoggedThisMeal else { return }

          try await performQuickAdd()
        } label: {
          if !hasLoggedThisMeal {
            Image(systemSymbol: .plusCircleFill)
              .foregroundStyle(.tint, .tint.tertiary)
              .font(.largeTitle)
          } else {
            Image(systemSymbol: .checkmarkCircleFill)
              .foregroundStyle(.white, .tint)
              .font(.largeTitle)
          }
        }
        .sensoryFeedback(.success, trigger: saveComplete)
      }
      .padding(.horizontal)
    }
    .padding(.bottom)
    .cardContainer(includePadding: false)
    .selectable()
  }
}

private extension MealRecordCell {

  var macrosDescription: String {
    let protein = NumberFormatter.noDecimalPlaces.string(for: mealRecord.totalProtein) ?? "0"
    let carbs = NumberFormatter.noDecimalPlaces.string(for: mealRecord.totalCarbs) ?? "0"
    let fat = NumberFormatter.noDecimalPlaces.string(for: mealRecord.totalFat) ?? "0"

    return "\(protein)g Protein • \(carbs)g Carbs • \(fat)g Fat"
  }

  var caloriesDescription: String {
    let totalCalories = mealRecord.totalCalories

    return "\(NumberFormatter.noDecimalPlaces.string(for: totalCalories) ?? "0") Cals"
  }

  func performQuickAdd() async throws {
    try await nutritionViewModel.log(
      modelContext: modelContext,
      mealRecord: mealRecord,
      numberOfServings: 1,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )

    hasLoggedThisMeal = true
    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        MealRecordCell(
          mealRecord: MealRecord.Preview.crackersAndCheese
        )
        MealRecordCell(
          mealRecord: MealRecord.Preview.crackersAndCheeseNoImage
        )
      }
      .horizontallyCentered()
      .padding()
    }
    .groupedBackground()
  }
}
