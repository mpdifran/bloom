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
    if #available(iOS 26.0, *) {
      Button {
        action()
      } label: {
        HStack {
          Image(systemSymbol: symbol)
            .font(.title3)
            .foregroundStyle(.tint)
          Text(title)
            .font(.subheadline)
            .foregroundStyle(.text)
            .bold()
            .fontDesign(.rounded)
            .fixedSize(horizontal: true, vertical: false)
        }
        .lineLimit(1)
        .padding()
      }
      .glassEffect(in: Capsule())
    } else {
      Button {
        action()
      } label: {
        VStack {
          Image(systemSymbol: symbol)
            .font(.title2)
            .foregroundStyle(.tint)
            .frame(height: 25)
          Text(title)
            .foregroundStyle(.primary)
            .bold()
            .fontDesign(.rounded)
        }
        .lineLimit(1)
        .font(.caption)
        .horizontallyCentered()
        .padding(6)
        .cardContainer(
          stroke: .fill,
          lineWidth: 0.5,
          includePadding: false
        )
      }
      .buttonStyle(.plain)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Scan") {

        }

        FoodSearchActionButton(symbol: .plus, title: "Quick Add") {

        }

        FoodSearchActionButton(symbol: .textBubble, title: "Text") {

        }
      }
    }
  }
}
