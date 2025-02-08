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

  @Namespace private var aiFoodScannerNamespace

  private let nutritionViewModel = NutritionTrackingViewModel.shared

  var body: some View {
    NavigationStack {
      VStack {
        if viewModel.servings.isNotEmpty {
          scrollContentView
        } else {
          fixedContentView
        }
      }
      .groupedBackground()
      .navigationTitle("AI Scan")
      .navigationBarTitleDisplayMode(.inline)
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
    .animation(.default, value: viewModel.image)
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
    .onChange(of: viewModel.servings.count) { oldValue, newValue in
      guard newValue > 0 else { return }

      scanResultsToggle.toggle()
    }
    .onChange(of: viewModel.error as? NSError) { oldValue, newValue in
      guard newValue != nil else { return }

      errorToggle.toggle()
    }
  }
}

private extension AIFoodScannerView {

  var fixedContentView: some View {
    VStack {
      AICameraScannerView(
        cameraManager: viewModel.cameraManager,
        captureSession: viewModel.captureSession,
        image: $viewModel.image
      )
      .fixedSize(horizontal: false, vertical: true)
      .matchedGeometryEffect(id: "aiCameraScannerView", in: aiFoodScannerNamespace)

      if viewModel.isLoading {
        analyzingView
      } else if !viewModel.hasScannedAtLeastOnce {
        instructionView
      } else if viewModel.servings.isEmpty {
        noResultsView
      }

      Button {
        scanFoodItems()
      } label: {
        Text("Scan")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .disabled(viewModel.isLoading)
    }
    .padding()
  }

  var scrollContentView: some View {
    ScrollView {
      VStack {
        HStack {
          AICameraScannerView(
            cameraManager: viewModel.cameraManager,
            captureSession: viewModel.captureSession,
            image: $viewModel.image
          )
          .frame(square: 100)
          .matchedGeometryEffect(id: "aiCameraScannerView", in: aiFoodScannerNamespace)

          VStack(alignment: .leading) {
            Text("This is the name of the food")
              .font(.title3)
              .bold()
              .fontDesign(.rounded)
          }
        }

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
      .padding()
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          viewModel.reset()
        } label: {
          Text("Rescan")
        }
      }
    }
    .shelf {
      if focusedIndex != nil {
        textEditorButton
      } else {
        logFoodButton
      }
    }
  }

  var logFoodButton: some View {
    AsyncButton {
      try await save()
      dismiss()
    } label: {
      Text("Log")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  var textEditorButton: some View {
    Button {
      focusedIndex = nil
    } label: {
      Text("Done")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  var instructionView: some View {
    VStack {
      Spacer()
      ContentUnavailableView("Scan Food", systemImage: "fork.knife")
      Spacer()
    }
  }

  var noResultsView: some View {
    VStack {
      Spacer()
      ContentUnavailableView("No Food Identified", systemImage: "fork.knife")
      Spacer()
    }
  }

  var analyzingView: some View {
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
}

private extension AIFoodScannerView {

  func onDetect(code: String) {

  }

  func scanFoodItems() {
    startScanToggle.toggle()

    guard permissionManager.permissionState == .granted else {
      alertDetails = permissionManager.permissionAlert
      return
    }

    viewModel.captureImage()
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
