//
//  FoodItemLogCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct FoodItemLogCell: View {
  let foodItemLog: FoodItemLog
  let showDetails: (FoodItemRecord) -> Void
  let showMealDetails: (FoodItemLog) -> Void
  let image: UIImage?

  init(
    foodItemLog: FoodItemLog,
    showDetails: @escaping (FoodItemRecord) -> Void,
    showMealDetails: @escaping (FoodItemLog) -> Void
  ) {
    self.foodItemLog = foodItemLog
    self.showDetails = showDetails
    self.showMealDetails = showMealDetails
    self.image = foodItemLog.image
  }

  @State private var isExpanded = false

  var body: some View {
    if foodItemLog.hasSingleServing, let serving = foodItemLog.firstFoodItemServing {
      foodItemContentView(serving: serving)
        .selectable()
        .cardContainer()
    } else {
      foodItemLogDisclosureView
    }
  }
}

private extension FoodItemLogCell {

  @ViewBuilder
  func foodItemContentView(serving: FoodItemServing) -> some View {
    if let foodItem = serving.foodItem {
      HStack {
        if foodItem.isVerified {
          verifiedBadge
        }

        VStack(alignment: .leading) {
          Text(foodItem.name)
            .font(.body)
            .fontDesign(.rounded)
            .bold()

          Text(subtitle(for: foodItem))
            .bold()
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .multilineTextAlignment(.leading)

        Spacer()

        Text("\(serving.totalCalories.format()) cals")
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)

        DisclosureIndicator()
      }
      .selectable()
      .onTapGesture {
        showDetails(foodItem)
      }
    }
  }

  var foodItemLogDisclosureView: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      ForEach(foodItemLog.foodItemServings ?? []) { serving in
        VStack(spacing: 0) {
          Divider()

          foodItemContentView(serving: serving)
            .padding(.vertical)
        }
        .padding(.horizontal)
      }

      Divider()
        .padding(.horizontal)

      Button {
        showMealDetails(foodItemLog)
      } label: {
        Text("Edit Meal")
          .foregroundStyle(.tint)
          .bold()
          .horizontallyCentered()
          .frame(minHeight: 60)
      }
    } label: {
      foodItemLogContentView
    }
    .disclosureGroupStyle(.foodItemLogCell)
  }

  var foodItemLogContentView: some View {
    HStack(alignment: .center, spacing: 0) {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(square: 80)
          .clipShape(RoundedRectangle(cornerRadius: 18))
          .padding(.vertical, 8)
          .padding(.leading, 8)
      }

      HStack {
        VStack(alignment: .leading) {
          Text(foodItemLog.name ?? "")
            .font(.body)
            .fontDesign(.rounded)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .bold()
            .fixedSize(horizontal: false, vertical: true)

          Text("\(foodItemLog.foodItemServings?.count ?? 0) items")
            .bold()
            .foregroundStyle(.secondary)
            .font(.caption)
        }

        Spacer()

        Text("\(foodItemLog.totalCalories.format()) cals")
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
          .fontDesign(.rounded)
      }
      .padding(.vertical)
      .padding(.leading)
    }
  }
}

private extension FoodItemLogCell {

  var verifiedBadge: some View {
    Image(systemSymbol: .checkmarkShieldFill)
      .foregroundStyle(.white, .mutedGreen)
      .fontDesign(.rounded)
      .bold()
  }
}

private extension FoodItemLogCell {

  func subtitle(for foodItem: FoodItemRecord) -> String {
    var components = [String]()
    if foodItem.brandName.isNotEmpty {
      components.append(foodItem.brandName)
    }
    if foodItem.flavour.isNotEmpty {
      components.append(foodItem.flavour)
    }

    components.append(servingAmountDescription(foodItem: foodItem))

    return components.joined(separator: " • ")
  }

  func servingAmountDescription(foodItem: FoodItemRecord) -> String {
    guard let servingValue = foodItem.servingValue else { return "" }

    return "\(servingValue.format()) \(foodItem.servingUnitString ?? "")"
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack(spacing: 10) {
        FoodItemLogCell(
          foodItemLog: FoodItemLog(
            id: "123",
            name: nil,
            date: .now,
            meal: .snack,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: [
              FoodItemServing(
                numberOfServings: 2,
                foodItem: .Preview.ritzCrackers
              )
            ]
          )
        ) { (_) in }
        showMealDetails: { (_) in }

        FoodItemLogCell(
          foodItemLog: FoodItemLog(
            id: "456",
            name: "Crackers with Cheese",
            date: .now,
            meal: .snack,
            numberOfServings: 2,
            imageData: UIImage(named: "CrackersAndCheese")?.pngData(),
            foodItemServings: [
              FoodItemServing(
                numberOfServings: 2,
                foodItem: .Preview.ritzCrackers
              ),
              FoodItemServing(
                numberOfServings: 3,
                foodItem: .Preview.shreddedCheddar
              )
            ]
          )
        ) { (_) in }
        showMealDetails: { (_) in }

        FoodItemLogCell(
          foodItemLog: FoodItemLog(
            id: "789",
            name: nil,
            date: .now,
            meal: .snack,
            numberOfServings: 1,
            imageData: nil,
            foodItemServings: [
              FoodItemServing(
                numberOfServings: 2,
                foodItem: .Preview.ritzCrackers
              )
            ]
          )
        ) { (_) in }
        showMealDetails: { (_) in }
      }
      .horizontallyCentered()
      .padding()
    }
    .groupedBackground()
  }
}
