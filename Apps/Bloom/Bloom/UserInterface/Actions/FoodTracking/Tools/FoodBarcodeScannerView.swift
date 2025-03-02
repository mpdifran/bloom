//
//  FoodBarcodeScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-10.
//

import SFSafeSymbols
import SwiftUI
import VisionKit

struct FoodBarcodeScannerView: View {
  let onBarcodeScan: @MainActor (String) -> Void

  @State private var shouldCapturePhoto = false
  @State private var capturedPhoto: IdentifiableImage?
  @State private var recognizedItems = [RecognizedItem]()
  @State private var recognizedItem: String?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    DataScannerView(
      shouldCapturePhoto: $shouldCapturePhoto,
      capturedPhoto: $capturedPhoto,
      recognizedItems: $recognizedItems,
      recognizedDataType: .barcode()
    )
    .ignoresSafeArea()
    .overlay {
      dismissButton
        .zStackAlignment(.topLeading)

      scannedCodeView
        .zStackAlignment(.bottom)
    }
    .animation(.default, value: recognizedBarcode)
    .presentationCompactAdaptation(.fullScreenCover)
    .onChange(of: recognizedBarcode) { oldValue, newValue in
      guard
        let newValue,
        recognizedItem == nil
      else { return }

      self.recognizedItem = newValue

      Task {
        await Delay(1000)
        await MainActor.run {
          self.onBarcodeScan(newValue)
          dismiss()
        }
      }
    }
  }
}

private extension FoodBarcodeScannerView {

  var recognizedBarcode: String? {
    guard let item = recognizedItems.last else { return nil }

    switch item {
    case .barcode(let barcode):
      return barcode.payloadStringValue
    default:
      return nil
    }
  }

  @ViewBuilder
  var scannedCodeView: some View {
    if let code = recognizedBarcode {
      BarcodeView(barcode: code)
        .horizontallyCentered()
        .cardContainer(fill: .regularMaterial)
        .padding()
        .transition(.blurReplace)
    }
  }

  var dismissButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemSymbol: .xmarkCircleFill)
        .foregroundStyle(.white, .gray)
        .font(.title)
    }
    .frame(square: 44)
    .padding()
  }
}

#Preview {
  FoodBarcodeScannerView { (_) in }
}
