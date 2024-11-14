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

    private let barcodeGenerator = BarcodeGenerator()

    var body: some View {
        barcodeGenerator.generateBarcode(text: barcode)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                ZStack {
                    if let first = barcode.first {
                        buildBarcodeText("\(first)")
                            .zStackAlignment(.bottomLeading)
                    }

                    buildBarcodeText(mainBarcodeString)
                        .zStackAlignment(.bottom)

                    if let last = barcode.last {
                        buildBarcodeText("\(last)")
                            .zStackAlignment(.bottomTrailing)
                    }
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private extension BarcodeView {

    var mainBarcodeString: String {
        String(barcode.dropFirst().dropLast())
    }

    func buildBarcodeText(_ content: String) -> some View {
        Text(content)
            .foregroundStyle(.black)
            .font(.system(size: 22))
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
    BarcodeView(barcode: "012345678902")
}
