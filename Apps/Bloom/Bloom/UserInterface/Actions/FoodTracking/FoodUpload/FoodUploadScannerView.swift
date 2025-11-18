//
//  FoodUploadScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomModel
import CoreLocation

struct FoodUploadScannerView: View {

  @Bindable private var viewModel: ViewModel
  private let onSuccess: (FoodItem) -> Void

  init(barcode: String? = nil, onSuccess: @escaping (FoodItem) -> Void) {
    self._viewModel = Bindable(ViewModel(barcode: barcode))
    self.onSuccess = onSuccess
  }

  @StateObject private var locationViewModel = LocationManagerViewModel.shared

  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading {
          loadingView
        } else {
          ScrollView {
            VStack {
              countrySection
              barcodeSection
              packagingSection
              nutritionLabelSection
            }
            .padding()
          }
        }
      }
      .navigationTitle("Upload Food")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
      .sheet($presentedSheet)
      .shelf {
        AsyncButton {
          await upload()
        } label: {
          Label("Upload", systemSymbol: .arrowUpCircleFill)
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(!viewModel.canUpload)
      }
    }
    .animation(.default, value: viewModel.barcode)
    .animation(.default, value: viewModel.nutritionLabelImage)
    .animation(.default, value: viewModel.packagingImage)
    .presentationCompactAdaptation(.fullScreenCover)
    .alert(error: $error)
    .alert(alertDetails: $viewModel.alertDetails)
    .onChange(of: locationViewModel.country) { oldValue, newValue in
      guard let country = newValue else { return }

      viewModel.country = country
    }
    .onAppear {
      viewModel.onAppear()
    }
  }
}

private extension FoodUploadScannerView {

  func upload() async {
    do {
      let foodItem = try await viewModel.upload()
      onSuccess(foodItem)
      dismiss()
    } catch { self.error = error }
  }
}

private extension FoodUploadScannerView {

  @ViewBuilder
  var countrySection: some View {
    SectionTitleView("Country")
      .padding(.horizontal)

    VStack {
      LabeledContent("Country") {
        TextField("Country", text: $viewModel.country)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.none)
      }
    }
    .cardContainer(fill: .background.secondary)
  }

  @ViewBuilder
  var barcodeSection: some View {
    SectionTitleView("1. Barcode")
      .padding(.horizontal)
    VStack {
      if let barcode = viewModel.barcode {
        BarcodeView(barcode: barcode)
          .horizontallyCentered()

        UploadFoodActionView(
          title: "Scan Again",
          symbol: .barcodeViewfinder
        )
      } else {
        UploadFoodActionView(
          title: "Scan Barcode",
          symbol: .barcodeViewfinder
        )
        .frame(minHeight: 100)
      }
    }
    .cardContainer(fill: .background.secondary)
    .onTapGesture {
      presentedSheet = FoodBarcodeScannerView { (barcode) in
        viewModel.barcode = barcode
      }.asAny
    }
  }

  @ViewBuilder
  var packagingSection: some View {
    SectionTitleView("2. Packaging")
      .padding(.horizontal)
    VStack {
      if let packagingImage = viewModel.packagingImage {
        Image(uiImage: packagingImage)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        UploadFoodActionView(
          title: "Scan Again",
          symbol: .vialViewfinder
        )
      } else {
        UploadFoodActionView(
          title: "Scan Packaging",
          symbol: .vialViewfinder
        )
        .frame(minHeight: 100)
      }
    }
    .cardContainer(fill: .background.secondary)
    .onTapGesture {
      presentedSheet = CameraView(
        capturedImage: $viewModel.packagingImage,
        instructions: "Position your package within the frame",
        aspectRatio: 0.8
      ).asAny
    }
    Text("Make sure to get the front of the packaging, including the brand and product name.")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal)
  }

  @ViewBuilder
  var nutritionLabelSection: some View {
    SectionTitleView("3. Nutrition Label")
      .padding(.horizontal)
    VStack {
      if let nutritionLabelImage = viewModel.nutritionLabelImage {
        Image(uiImage: nutritionLabelImage)
          .resizable()
          .scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 16))

        UploadFoodActionView(
          title: "Scan Again",
          symbol: .textViewfinder
        )
      } else {
        UploadFoodActionView(
          title: "Scan Nutrition Label",
          symbol: .textViewfinder
        )
        .frame(minHeight: 100)
      }
    }
    .cardContainer(fill: .background.secondary)
    .onTapGesture {
      presentedSheet = CameraView(
        capturedImage: $viewModel.nutritionLabelImage,
        instructions: "Position the nutrition label within the frame",
        aspectRatio: 0.8
      ).asAny
    }
    Text("For best results, try and get a clear picture of the entire nutrition label.")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal)
  }

  var loadingView: some View {
    VStack {
      Spacer()
      CircularSpinnerView()
        .foregroundStyle(.tint)
      Text("Uploading...")
        .font(.title2)
        .bold()
        .fontDesign(.rounded)
      Spacer()
    }
    .horizontallyCentered()
  }
}

#Preview {
  FoodUploadScannerView() { (_) in

  }
}
