//
//  FoodUploadScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SwiftUI
import AppUI

struct FoodUploadScannerView: View {

    @Bindable private var viewModel = ViewModel()

    @State private var presentedSheet: AnyView?
    @State private var error: Error?

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
                    Task { await upload() }
                }
                .disabled(!viewModel.canUpload)
            }
        }
        .animation(.default, value: viewModel.barcode)
        .animation(.default, value: viewModel.nutritionLabelImage)
        .animation(.default, value: viewModel.packagingImage)
        .presentationCompactAdaptation(.fullScreenCover)
        .alert(error: $error)
        .alert(alertDetails: $viewModel.alertDetails)
    }
}

private extension FoodUploadScannerView {

    func upload() async {
        do {
            try await viewModel.upload()
        } catch { self.error = error }
    }
}

private extension FoodUploadScannerView {

    @ViewBuilder
    var barcodeSection: some View {
        SectionTitleView("Barcode")
            .padding(.horizontal)
        VStack {
            if let barcode = viewModel.barcode {
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
            presentedSheet = FoodBarcodeScannerView { (barcode) in
                viewModel.barcode = barcode
            }.asAny
        }
    }

    @ViewBuilder
    var nutritionLabelSection: some View {
        SectionTitleView("Nutrition Label")
            .padding(.horizontal)
        VStack {
            if let nutritionLabelImage = viewModel.nutritionLabelImage {
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
            presentedSheet = CameraPhotoPicker(image: $viewModel.nutritionLabelImage).asAny
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
            if let packagingImage = viewModel.packagingImage {
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
            presentedSheet = CameraView(capturedImage: $viewModel.packagingImage).asAny
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
