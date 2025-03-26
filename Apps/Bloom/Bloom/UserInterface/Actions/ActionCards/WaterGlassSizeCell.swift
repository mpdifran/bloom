//
//  WaterGlassSizeCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI

struct WaterGlassSizeCell: View {
  let model: WaterGlassSizeModel

  var body: some View {
    HStack {
      Image(systemSymbol: .waterbottle)
        .foregroundStyle(.tint)

      Text(model.name)
        .fontDesign(.rounded)
        .bold()

      Spacer()

      Text(model.displayValue)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      WaterGlassSizeCell(
        model: WaterGlassSizeModel(
          name: "Waterbottle",
          quantityValue: 400,
          unit: .literUnit(with: .milli)
        )
      )
    }
    .padding()
  }
}
