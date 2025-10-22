//
//  BarcodeScannerLoadingCell.swift
//  Bloom
//
//  Created by Claude on 2025-10-22.
//

import SwiftUI
import AppUI

struct BarcodeScannerLoadingCell: View {
  let barcode: String

  var body: some View {
    HStack {
      HStack {
        BarcodeView(barcode: barcode)
          .frame(height: 60)

        Spacer()

        Text("Searching...")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .shimmer()
      }
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BarcodeScannerLoadingCell(barcode: "012345678902")
      BarcodeScannerLoadingCell(barcode: "987654321098")
    }
  }
}
