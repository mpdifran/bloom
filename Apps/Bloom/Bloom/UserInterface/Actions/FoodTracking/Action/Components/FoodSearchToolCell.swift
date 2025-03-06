//
//  FoodSearchToolCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-08.
//

import SFSafeSymbols
import SwiftUI

struct FoodSearchToolCell: View {
  let title: String
  let symbol: SFSymbol

  var body: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: symbol)
      Text(title)
    }
    .bold()
    .foregroundStyle(.tint)
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background {
      Capsule()
        .fill(.tint.quinary)
    }
  }
}

#Preview {
  FoodSearchToolCell(
    title: "Scan",
    symbol: .barcodeViewfinder
  )
  FoodSearchToolCell(
    title: "AI Photo",
    symbol: .cameraViewfinder
  )
}
