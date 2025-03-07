//
//  FoodSearchActionButton.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-06.
//

import SwiftUI
import SFSafeSymbols

struct FoodSearchActionButton: View {
  let symbol: SFSymbol
  let title: String
  let action: () -> Void

  init(
    symbol: SFSymbol,
    title: String,
    action: @escaping () -> Void
  ) {
    self.symbol = symbol
    self.title = title
    self.action = action
  }

  var body: some View {
    Button {
      action()
    } label: {
      HStack {
        Image(systemSymbol: symbol)
          .foregroundStyle(.tint)
        Text(title)
          .foregroundStyle(.primary)
      }
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .font(.headline)
      .horizontallyCentered()
      .cardContainer()
    }
    .buttonStyle(.plain)
    .bold()
  }
}

#Preview {
  HStack {
    FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Scan") {

    }

    FoodSearchActionButton(symbol: .plus, title: "Quick Add") {

    }

    FoodSearchActionButton(symbol: .textBubble, title: "Text") {

    }
  }
  .padding()
  .tint(.mutedPurple)
  .groupedBackground()
}
