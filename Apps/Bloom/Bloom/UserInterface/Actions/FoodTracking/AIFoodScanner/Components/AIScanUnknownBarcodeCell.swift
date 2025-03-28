//
//  AIScanUnknownBarcodeCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-11.
//

import SFSafeSymbols
import SwiftUI
import AppUI

struct AIScanUnknownBarcodeCell: View {
  let barcode: String
  let performUpload: () -> Void

  var body: some View {
    HStack {
      VStack {
        BarcodeView(barcode: barcode)
          .frame(height: 80)

        Label("Unknown Barcode", systemSymbol: .exclamationmarkTriangleFill)
          .font(.caption)
          .bold()
          .foregroundStyle(.mutedRed)
      }

      Spacer()

      Button {
        performUpload()
      } label: {
        Text("Upload")
          .bold()
      }
      .buttonStyle(.primary)
    }
    .cardContainer(fill: .background, stroke: .background.secondary)
  }
}

#Preview {
  VStack {
    AIScanUnknownBarcodeCell(barcode: "12345678") { }
  }
  .padding()
  .groupedBackground()
}
