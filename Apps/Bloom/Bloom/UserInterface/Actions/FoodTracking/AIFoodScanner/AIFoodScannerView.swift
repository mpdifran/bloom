//
//  AIFoodScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SwiftUI
import AppUI
import BloomModel
import AVFoundation

struct AIFoodScannerView: View {

  @State private var viewModel = ViewModel()

  @State private var startScanToggle = false
  @State private var scanResultsToggle = false
  @State private var saveComplete = false
  @State private var errorToggle = false
  @State private var alertDetails: AlertDetails?
  @FocusState private var focusedIndex: Int?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  private let nutritionViewModel = NutritionTrackingViewModel.shared

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          HStack {
            AICameraScannerView(
              cameraManager: viewModel.cameraManager,
              captureSession: viewModel.captureSession,
              image: $viewModel.image
            ) {
              viewModel.reset()
            }
            .if(viewModel.image != nil) {
              $0.frame(square: 100)
            }

            if viewModel.image != nil {
              Text("This is the name of the food")

              Spacer()
            }
          }

          scannedItemsView
        }
        .padding()
      }
      .groupedBackground()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }.bold()
        }
      }
    }
    .sensoryFeedback(.error, trigger: errorToggle)
    .sensoryFeedback(.impact, trigger: startScanToggle)
    .sensoryFeedback(.success, trigger: scanResultsToggle)
    .sensoryFeedback(.success, trigger: saveComplete)
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.easeInOut, value: viewModel.image)
    .animation(.default, value: viewModel.isLoading)
    .tint(.mutedGreen)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          await viewModel.cameraManager.start()
        }
      }
    }
    .onDisappear {
      Task {
        await viewModel.cameraManager.stop()
      }
    }
    .alert(alertDetails: $alertDetails)
    .alert(error: $viewModel.error)
    .onChange(of: viewModel.error as? NSError) { oldValue, newValue in
      guard newValue != nil else { return }

      errorToggle.toggle()
    }
  }
}

private extension AIFoodScannerView {

  var scannedItemsView: some View {
    VStack {
      if viewModel.isLoading {
        VStack {
          Spacer()
          CircularSpinnerView()
            .foregroundStyle(.tint)
          Text("Analyzing...")
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
          Spacer()
        }
        .horizontallyCentered()
      } else if !viewModel.hasScannedAtLeastOnce {
        Spacer()
        ContentUnavailableView("Scan Food", systemImage: "fork.knife")
        Spacer()
      } else {
        VStack(spacing: 0) {
          if viewModel.servings.isEmpty {
            Spacer()
            ContentUnavailableView("No Food Identified", systemImage: "fork.knife")
            Spacer()
          } else {
            foodResultsHeader

            ScrollView {
              VStack {
                SectionTitleView("Identified Food")
                  .padding(.horizontal)
                ForEachEnumerated(viewModel.servings) { (index, serving) in
                  if viewModel.servings.count > index { // Fixes dumb bug where viewModel.servings is empty but we try and load a cell.
                    AIScanFoodItemCell(foodItemServing: $viewModel.servings[index])
                      .focused($focusedIndex, equals: index)
                  }
                }
              }
            }
          }
        }
        .padding(.horizontal)
      }

      HStack(spacing: 6) {
        if focusedIndex != nil {
          textEditorBottomBar
        } else {
          logFoodBottomBar
        }
      }
    }
  }
}

private extension AIFoodScannerView {

  @ViewBuilder
  var foodResultsHeader: some View {
    FoodItemLogPickerHeader()
      .horizontallyCentered()
      .padding(.vertical, 4)
      .background {
        Button {
          viewModel.reset()
        } label: {
          Image(systemName: "arrow.counterclockwise")
            .bold()
        }
        .horizontalAlignment(.trailing)
      }
    Divider()
  }

  @ViewBuilder
  var logFoodBottomBar: some View {
    if viewModel.servings.isNotEmpty {
      AsyncButton {
        try await save()
        dismiss()
      } label: {
        Text("Log")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    } else {
      Button {
        scanFoodItems()
      } label: {
        Text("Scan")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .disabled(viewModel.isLoading)
    }
  }

  var textEditorBottomBar: some View {
    Button {
      focusedIndex = nil
    } label: {
      Text("Done")
        .bold()
        .horizontallyCentered()
        .frame(height: 55)
        .background {
          RoundedRectangle(cornerRadius: 16)
            .fill(.tint)
        }
        .foregroundStyle(.white)
    }
  }
}

private extension AIFoodScannerView {

  func onDetect(code: String) {

  }

  func scanFoodItems() {
    startScanToggle.toggle()
    Task {
      guard permissionManager.permissionState == .granted else {
        alertDetails = permissionManager.permissionAlert
        return
      }

      await viewModel.captureImage()

      if viewModel.servings.isNotEmpty {
        scanResultsToggle.toggle()
      }
    }
  }

  func save() async throws {
    try await nutritionViewModel.log(
      foodItemServings: viewModel.servings,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  AIFoodScannerView()
}
