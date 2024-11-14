//
//  FoodUploadScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SwiftUI
import AppUI

struct FoodUploadScannerView: View {

    @State private var barcode: String?
    @State private var nutritionLabelImage: UIImage?
    @State private var packagingImage: UIImage?

    @State private var presentedSheet: AnyView?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    barcodeSection
                    packagingSection
                    nutritionLabelSection
                }
                .padding()
            }
            .navigationTitle("Upload Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet($presentedSheet)
            .shelf {
                ProminentButton("Upload", systemImage: "arrow.up.square.fill") {

                }
                .disabled(!canUpload)
            }
        }
        .animation(.default, value: barcode)
        .presentationCompactAdaptation(.fullScreenCover)
    }
}

private extension FoodUploadScannerView {

    var canUpload: Bool {
        barcode != nil && nutritionLabelImage != nil && packagingImage != nil
    }
}

private extension FoodUploadScannerView {

    @ViewBuilder
    var barcodeSection: some View {
        SectionTitleView("Barcode")
            .padding(.horizontal)
        VStack {
            if let barcode {
                BarcodeView(barcode: barcode)
                    .horizontallyCentered()

                UploadFoodActionView(
                    title: "Scan Again",
                    systemImage: "barcode.viewfinder"
                )
            } else {
                UploadFoodActionView(
                    title: "Scan Barcode",
                    systemImage: "barcode.viewfinder"
                )
                .frame(minHeight: 100)
            }
        }
        .cardContainer(fill: .background.secondary, stroke: .tint.secondary)
        .onTapGesture {
            presentedSheet = FoodBarcodeScannerView() { barcode in
                self.barcode = barcode
            }.asAny
        }
    }

    @ViewBuilder
    var nutritionLabelSection: some View {
        SectionTitleView("Nutrition Label")
            .padding(.horizontal)
        VStack {
            if let nutritionLabelImage {
                Image(uiImage: nutritionLabelImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                UploadFoodActionView(
                    title: "Scan Again",
                    systemImage: "text.viewfinder"
                )
            } else {
                UploadFoodActionView(
                    title: "Scan Nutrition Label",
                    systemImage: "text.viewfinder"
                )
                .frame(minHeight: 100)
            }
        }
        .cardContainer(fill: .background.secondary, stroke: .tint.secondary)
        .onTapGesture {
            presentedSheet = CameraPhotoPicker(image: $nutritionLabelImage).asAny
        }
        Text("For best results, try and get a clear picture of the entire nutrition label.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }

    @ViewBuilder
    var packagingSection: some View {
        SectionTitleView("Packaging")
            .padding(.horizontal)
        VStack {
            if let packagingImage {
                Image(uiImage: packagingImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                UploadFoodActionView(
                    title: "Scan Again",
                    systemImage: "vial.viewfinder"
                )
            } else {
                UploadFoodActionView(
                    title: "Scan Packaging",
                    systemImage: "vial.viewfinder"
                )
                .frame(minHeight: 100)
            }
        }
        .cardContainer(fill: .background.secondary, stroke: .tint.secondary)
        .onTapGesture {
            presentedSheet = CameraPhotoPicker(image: $packagingImage).asAny
        }
        Text("Make sure to get the front of the packaging, including the brand and product name.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }
}

#Preview {
    FoodUploadScannerView()
}
