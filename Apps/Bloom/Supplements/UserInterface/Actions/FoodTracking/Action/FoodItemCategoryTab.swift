//
//  FoodItemCategoryTab.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-14.
//

import SwiftUI
import AppUI

enum FoodItemCategoryTab: TabFilterItem {
  var id: Self { self }

  case branded
  case generic
  case restaurant
  case fastFood

  var name: String {
    switch self {
    case .branded: return "Branded"
    case .generic: return "Generic"
    case .restaurant: return "Restaurant"
    case .fastFood: return "Fast Food"
    }
  }

  var image: Image {
    switch self {
    case .branded: return Image(systemName: "barcode")
    case .generic: return Image(systemName: "carrot")
    case .restaurant: return Image(systemName: "fork.knife")
    case .fastFood: return Image(systemName: "bag")
    }
  }

  var color: Color {
    switch self {
    case .branded:
        .mutedGreen
    case .generic:
        .mutedBlue
    case .restaurant:
        .mutedPurple
    case .fastFood:
        .mutedYellow
    }
  }
}
