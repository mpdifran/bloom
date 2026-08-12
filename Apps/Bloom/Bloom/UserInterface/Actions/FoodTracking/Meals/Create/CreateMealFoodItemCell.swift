//
//  CreateMealFoodItemCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI
import BloomModel

struct CreateMealFoodItemCell: View {
  let foodItem: FoodItem
  @Binding var numberOfServings: Double
  let onDelete: () -> Void

  var body: some View {
    HStack {
      if foodItem.isVerified {
        Image(systemSymbol: .checkmarkShieldFill)
          .foregroundStyle(.white, .mutedGreen)
          .fontDesign(.rounded)
          .bold()
      }

      VStack(alignment: .leading) {
        Text(foodItem.name)
          .fontDesign(.rounded)
          .bold()

        Text(subtitle)
          .bold()
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      .multilineTextAlignment(.leading)

      Spacer()

      TextField("", value: $numberOfServings, formatter: NumberFormatter.threeDecimalPlaces)
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .frame(width: 70)
        .fontDesign(.rounded)
        .keyboardType(.decimalPad)
        .selectAllTextOnBeginEditing()

      Button {
        onDelete()
      } label: {
        Image(systemSymbol: .minusCircleFill)
          .foregroundStyle(.white, .mutedRed)
          .font(.title2)
          .padding(.leading)
      }
    }
  }
}

private extension CreateMealFoodItemCell {

  var subtitle: String {
    var components = [String]()
    if let brandName = foodItem.brandName, brandName.isNotEmpty {
      components.append(brandName)
    }
    if let flavour = foodItem.flavour, flavour.isNotEmpty {
      components.append(flavour)
    }
    if let formattedServingQuantity {
      components.append(formattedServingQuantity)
    }

    return components.joined(separator: String(localized: " • "))
  }

  var formattedServingQuantity: String? {
    guard let quantity = foodItem.servingQuantity else { return nil }

    return "\(quantity.value.format(using: .twoDecimalPlaces)) \(quantity.unit)"
  }
}

#Preview {
  @Previewable @State var tomatoesServings: Double = 1
  @Previewable @State var crackersServings: Double = 1
  @Previewable @State var salmonServings: Double = 1

  PreviewEnvironment {
    ScrollView {
      VStack {
        CreateMealFoodItemCell(
          foodItem: .Preview.cherryTomatoes,
          numberOfServings: $tomatoesServings
        ) { }
        CreateMealFoodItemCell(
          foodItem: .Preview.ritzCrackers,
          numberOfServings: $crackersServings
        ) { }
        CreateMealFoodItemCell(
          foodItem: .Preview.grilledSalmon,
          numberOfServings: $salmonServings
        ) { }
      }
      .padding()
    }
    .groupedBackground()
  }
}
