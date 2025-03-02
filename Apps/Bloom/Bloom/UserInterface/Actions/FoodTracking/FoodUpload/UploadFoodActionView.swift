//
//  UploadFoodActionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SFSafeSymbols
import SwiftUI

struct UploadFoodActionView: View {
  let title: String
  let symbol: SFSymbol

  var body: some View {
    HStack {
      Spacer()
      Image(systemSymbol: symbol)
        .font(.title)
      Text(title)
        .font(.title3)
        .bold()
      Spacer()
    }
    .fontDesign(.rounded)
    .foregroundStyle(.tint)
    .selectable()
  }
}

#Preview {
  UploadFoodActionView(
    title: "Scan Barcode",
    symbol: .barcodeViewfinder
  )
}
