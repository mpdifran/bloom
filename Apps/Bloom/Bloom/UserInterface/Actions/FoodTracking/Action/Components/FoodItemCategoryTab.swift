//
//  FoodItemCategoryTab.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-14.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomModel

enum FoodItemCategoryTab: TabFilterItem {
  var id: Self { self }

  case branded
  case generic
//  case restaurant
//  case fastFood

  var name: String {
    switch self {
    case .branded: return String(localized: "Branded", comment: "Display name for food item category tab")
    case .generic: return String(localized: "Generic", comment: "Display name for food item category tab")
//    case .restaurant: return String(localized: "Restaurant", comment: "Display name for food item category tab")
//    case .fastFood: return String(localized: "Fast Food", comment: "Display name for food item category tab")
    }
  }

  var image: Image {
    switch self {
    case .branded: return Image(systemSymbol: .barcode)
    case .generic: return Image(systemSymbol: .carrot)
//    case .restaurant: return Image(systemSymbol: .forkKnife)
//    case .fastFood: return Image(systemSymbol: .bag)
    }
  }

  var color: Color {
    switch self {
    case .branded:
        .mutedGreen
    case .generic:
        .mutedBlue
//    case .restaurant:
//        .mutedPurple
//    case .fastFood:
//        .mutedYellow
    }
  }

  var category: FoodItem.Category {
    switch self {
    case .branded: .branded
    case .generic: .generic
//    case .restaurant: .restaurant
//    case .fastFood: .fastfood
    }
  }
}
