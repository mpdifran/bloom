//
//  DrinkSubTypeSelectionView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI
import CoreHealth

struct DrinkSubTypeSelectionView: View {
  let parentDrink: DrinkType
  let onSubTypeSelected: (DrinkType) -> Void

  var body: some View {
    ScrollView {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)],
        spacing: 12
      ) {
        if let subTypes = parentDrink.subTypes {
          ForEach(subTypes) { subType in
            DrinkTypeCell(drink: subType)
              .onTapGesture {
                onSubTypeSelected(subType)
              }
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 100)
    }
    .sensoryFeedback(.selection, trigger: parentDrink.id)
  }
}

#Preview {
  let beer = DrinkType.defaultDrinks.first { $0.name == "Beer" }!

  DrinkSubTypeSelectionView(
    parentDrink: beer,
    onSubTypeSelected: { subType in
      print("Selected: \(subType.name)")
    }
  )
  .tint(.orange)
}
