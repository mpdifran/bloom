//
//  BarcodeGenerator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct BarcodeGenerator {
    let context = CIContext()
    let generator = CIFilter.code128BarcodeGenerator()

    func generateBarcode(text: String) -> Image {
        let generator = CIFilter.code128BarcodeGenerator()
        generator.message = Data(text.utf8)

        if let outputImage = generator.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 5, y: 5))

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                return Image(uiImage: uiImage)
            }
        }

        return Image(systemName: "barcode")
    }
}

#Preview {
    BarcodeGenerator().generateBarcode(text: "055577113028")

    BarcodeGenerator().generateBarcode(text: "055577113028")
        .resizable()
        .aspectRatio(contentMode: .fit)

    BarcodeGenerator().generateBarcode(text: "")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200)
}
