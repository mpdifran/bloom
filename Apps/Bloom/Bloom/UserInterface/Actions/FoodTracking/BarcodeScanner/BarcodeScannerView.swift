//
//  BarcodeScannerView.swift
//  Bloom
//
//  Created by Claude on 2025-10-22.
//

import SwiftUI
import BloomModel
import BloomUI
import AppUI

struct BarcodeScannerView: View {

  @State private var viewModel = ViewModel()

  @State private var presentedSheet: AnyView?
  @StateObject private var locationViewModel = LocationManagerViewModel.shared
  @State private var alertDetails: AlertDetails?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        cameraView

        if viewModel.barcodeStates.isNotEmpty {
          scannedItemsSection
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
        ToolbarItem(placement: .principal) {
          FoodItemLogPickerHeader()
        }
      }
    }
    .animation(.default, value: viewModel.barcodeStates.count)
    .sensoryFeedback(.success, trigger: viewModel.scanResultsToggle)
    .sensoryFeedback(.error, trigger: viewModel.scanResultsErrorToggle)
    .sheet($presentedSheet)
    .alert(alertDetails: $alertDetails)
    .presentationCompactAdaptation(.fullScreenCover)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          viewModel.cameraManager.start()
        } else {
          alertDetails = permissionManager.permissionAlert
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

private extension BarcodeScannerView {

  var cameraView: some View {
    AICameraScannerView(
      cameraManager: viewModel.cameraManager,
      image: .constant(nil)
    )
    .aspectRatio(2, contentMode: .fit)
    .fixedSize(horizontal: false, vertical: true)
  }

  var scannedItemsSection: some View {
    ScrollView {
      VStack {
        ForEach(viewModel.barcodeStates) { state in
          switch state {
          case .loading(let barcode):
            BarcodeScannerLoadingCell(barcode: barcode)
              .transition(.opacity)

          case .found(_, let foodItems):
            ForEach(foodItems) { foodItem in
              FoodItemCell(foodItem: foodItem)
                .id(foodItem.id)
                .transition(.opacity)
                .onTapGesture {
                  presentedSheet = FoodItemDetailsView(
                    foodItem: foodItem,
                    existingFoodItemLog: nil,
                    mode: .editAndView
                  ).asAny
                }
            }

          case .notFound(let barcode):
            AIScanUnknownBarcodeCell(barcode: barcode) {
              presentedSheet = FoodUploadScannerView(barcode: barcode) { foodItem in
                viewModel.added(foodItem: foodItem, for: barcode)
              }.asAny
            }
            .transition(.opacity)
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

      Text("Scan a barcode to log food")
        .font(.title3)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()
    }
  }
}

#Preview {
  PreviewEnvironment {
    BarcodeScannerView()
  }
}
