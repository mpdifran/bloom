//
//  BarcodeScannerPickerView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-11.
//

import SwiftUI
import BloomModel

struct BarcodeScannerPickerView: View {

  let selectFoodItem: (FoodItem) -> Void

  init(selectFoodItem: @escaping (FoodItem) -> Void) {
    self.selectFoodItem = selectFoodItem
  }

  @State private var viewModel = ViewModel()

  @State private var presentedSheet: AnyView?
  @State private var locationViewModel = LocationManagerViewModel.shared

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        cameraView

        if viewModel.foodItems.isNotEmpty || viewModel.unknownBarcodes.isNotEmpty {
          foodItemsSection
        } else {
          instructionsView
        }
      }
      .padding()
      .groupedBackground()
      .navigationTitle("Barcode Scan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .animation(.default, value: viewModel.foodItems)
    .sensoryFeedback(.success, trigger: viewModel.scanResultsToggle)
    .sensoryFeedback(.error, trigger: viewModel.scanResultsErrorToggle)
    .sheet($presentedSheet)
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          viewModel.cameraManager.start()
        }
      }
    }
    .onDisappear {
      viewModel.cameraManager.stop()
    }
    .onChange(of: locationViewModel.country) { _, newValue in
      guard let country = newValue else { return }

      viewModel.country = country
    }
  }
}

private extension BarcodeScannerPickerView {

  var cameraView: some View {
    AICameraScannerView(
      cameraManager: viewModel.cameraManager,
      image: .constant(nil)
    )
    .aspectRatio(2, contentMode: .fit)
    .fixedSize(horizontal: false, vertical: true)
  }

  var foodItemsSection: some View {
    ScrollView {
      VStack {
        ForEach(viewModel.foodItems) { foodItem in
          FoodItemPickerCell(foodItem: foodItem) {
            select(foodItem: foodItem)
          }
          .id(foodItem.id)
          .transition(.opacity)
          .onTapGesture {
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem,
              existingFoodItemLog: nil,
              mode: .viewOnly
            ).asAny
          }
        }

        if viewModel.unknownBarcodes.isNotEmpty {
          ForEach(viewModel.unknownBarcodes) { barcode in
            AIScanUnknownBarcodeCell(barcode: barcode) {
              presentedSheet = FoodUploadScannerView(barcode: barcode) { foodItem in
                viewModel.added(foodItem: foodItem, for: barcode)
              }.asAny
            }
            .transition(.blurReplace)
          }
        }
      }
      .padding(.vertical)
      .scrollIndicators(.hidden)
    }
  }

  var instructionsView: some View {
    VStack {
      Spacer(minLength: 0)

      HStack {
        Spacer(minLength: 0)

        Image(.barcodePackaging)
          .overlay {
            CameraReticuleShapeView(lineWidth: 6, cornerRadius: 5)
              .frame(width: 45, height: 40)
              .padding(.bottom, 12)
              .padding(.trailing, 12)
              .zStackAlignment(.bottomTrailing)
          }

        Spacer(minLength: 0)
      }
      .padding(.vertical)

      Text("Scan a barcode to add food")
        .font(.title3)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()
    }
  }
}

private extension BarcodeScannerPickerView {

  func select(foodItem: FoodItem) {
    selectFoodItem(foodItem)
    // dismiss is handled by the parent view
  }
}

#Preview {
  PreviewEnvironment {
    BarcodeScannerPickerView { _ in

    }
  }
}
