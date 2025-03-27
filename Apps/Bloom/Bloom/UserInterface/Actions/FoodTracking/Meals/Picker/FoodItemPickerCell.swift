//
//  FoodItemPickerCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI
import AppUI
import BloomModel
import SFSafeSymbols

struct FoodItemPickerCell: View {
  let foodItem: FoodItem
  let onSelect: () -> Void

  @State private var selectionToggle = false

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

      Button {
        selectionToggle.toggle()
        onSelect()
      } label: {
        Text("Select")
          .font(.caption)
      }
      .buttonStyle(.secondary)
      .sensoryFeedback(.success, trigger: selectionToggle)
    }
    .cardContainer()
  }
}

private extension FoodItemPickerCell {

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

    return components.joined(separator: " • ")
  }

  var formattedServingQuantity: String? {
    guard let quantity = foodItem.servingQuantity else { return nil }

    return "\(quantity.value.format(using: .twoDecimalPlaces)) \(quantity.unit)"
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        FoodItemPickerCell(foodItem: .Preview.cherryTomatoes) { }
        FoodItemPickerCell(foodItem: .Preview.ritzCrackers) { }
        FoodItemPickerCell(foodItem: .Preview.grilledSalmon) { }
      }
      .padding()
    }
    .groupedBackground()
  }
}
