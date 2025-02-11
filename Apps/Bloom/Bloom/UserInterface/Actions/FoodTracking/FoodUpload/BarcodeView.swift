//
//  BarcodeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SwiftUI
import AppUI

struct BarcodeView: View {
  let barcode: String

  init(barcode: String) {
    self.barcode = barcode
    self.barcodeImage = barcodeGenerator.generateBarcode(text: barcode)
  }

  private let barcodeImage: Image
  private let barcodeGenerator = BarcodeGenerator()


  var body: some View {
    barcodeImage
      .resizable()
      .aspectRatio(contentMode: .fit)
      .overlay {
        GeometryReader { geometry in
          ZStack {
            if let first = barcode.first {
              buildBarcodeText("\(first)", width: geometry.size.width)
                .zStackAlignment(.bottomLeading)
            }

            buildBarcodeText(mainBarcodeString, width: geometry.size.width)
              .zStackAlignment(.bottom)

            if let last = barcode.last {
              buildBarcodeText("\(last)", width: geometry.size.width)
                .zStackAlignment(.bottomTrailing)
            }
          }
          .padding(geometry.size.width / 30)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

private extension BarcodeView {

  var mainBarcodeString: String {
    String(barcode.dropFirst().dropLast())
  }

  func buildBarcodeText(_ content: String, width: CGFloat) -> some View {
    Text(content)
      .foregroundStyle(.black)
      .font(.system(size: width / 16))
      .bold()
      .fontDesign(.monospaced)
      .padding(4)
      .background {
        Rectangle()
          .fill(.white)
      }
  }
}

#Preview {
  VStack {
    Spacer()
    BarcodeView(barcode: "012345678902")
    BarcodeView(barcode: "012345678902")
      .frame(height: 60)
    Spacer()
  }
  .padding()
  .groupedBackground()
}
