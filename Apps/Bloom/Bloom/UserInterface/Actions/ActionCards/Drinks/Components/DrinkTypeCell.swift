//
//  DrinkTypeCell.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI

struct DrinkTypeCell: View {
  let drink: DrinkType

  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        // Background with drink color
        RoundedRectangle(cornerRadius: 16)
          .fill(.tint.tertiary)

        // Icon
        Image(systemName: drink.symbolName)
          .font(.system(size: 32))
          .foregroundStyle(.tint)
      }
      .frame(height: 80)

      // Name
      Text(drink.name)
        .font(.caption)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .lineLimit(2)
        .multilineTextAlignment(.center)
    }
    .padding(8)
    .background {
      RoundedRectangle(cornerRadius: 20)
        .fill(.tint.tertiary)
    }
    .contentShape(RoundedRectangle(cornerRadius: 20))
    .tint(drink.liquidColor)
  }
}

#Preview {
  ScrollView {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
      ForEach(DrinkType.defaultDrinks) { drink in
        DrinkTypeCell(drink: drink)
      }
    }
    .padding()
  }
}
