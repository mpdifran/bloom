//
//  DrinkCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-30.
//

import SwiftUI
import CoreHealth

struct DrinkCell: View {
  let drink: DrinkType

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(drink.liquidColor.opacity(0.2))

        Image(systemName: drink.symbolName)
          .font(.title3)
          .foregroundStyle(drink.liquidColor)
      }
      .frame(width: 44, height: 44)

      VStack(alignment: .leading, spacing: 2) {
        Text(drink.name)
          .font(.headline)
          .fontDesign(.rounded)
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  List {
    ForEach(DrinkType.defaultDrinks) { drink in
      DrinkCell(drink: drink)
    }
  }
}
