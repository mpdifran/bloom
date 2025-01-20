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

  init() {
    self.cameraManager = CameraManager.create(with: captureSession)
  }

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
  private let cameraManager: CameraManager
  private let captureSession = AVCaptureSession()

  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        scanAreaView
          .frame(height: proxy.size.height * imageScanAspect)
          .clipped()

        scannedItemsView
          .background {
            RoundedRectangle(cornerRadius: 30)
              .fill(.background)
              .ignoresSafeArea(edges: .bottom)
          }
          .padding(.top, -30)
      }
    }
    .sensoryFeedback(.error, trigger: errorToggle)
    .sensoryFeedback(.impact, trigger: startScanToggle)
    .sensoryFeedback(.success, trigger: scanResultsToggle)
    .sensoryFeedback(.success, trigger: saveComplete)
    .ignoresSafeArea(edges: .top)
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.bouncy, value: viewModel.image)
    .animation(.default, value: viewModel.isLoading)
    .tint(.mutedGreen)
    .onAppear {
      Task {
        await permissionManager.checkPermission()
        if permissionManager.permissionState == .granted {
          await cameraManager.start()
        }
      }
    }
    .onDisappear {
      Task {
        await cameraManager.stop()
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

  var imageScanAspect: CGFloat {
    if viewModel.image == nil {
      return 0.6
    }
    return 0.4
  }

  @ViewBuilder
  var scanAreaView: some View {
    switch permissionManager.permissionState {
    case .granted:
      cameraView
    case .denied:
      CameraPermissionDeniedView()
        .onAppear {
          alertDetails = permissionManager.permissionAlert
        }
    case .pending:
      Rectangle()
        .fill(.black)
        .ignoresSafeArea()
        .aspectRatio(contentMode: .fit)
    }
  }

  var cameraView: some View {
    ZStack {
      CameraPreview(
        session: captureSession,
        gravity: .resizeAspectFill
      ) { focusPoint in
        Task {
          await cameraManager.setFocus(for: focusPoint)
        }
      }

      if let image = viewModel.image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      }
    }
  }

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
      .padding()
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
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark")
        .bold()
        .frame(square: 55)
        .background {
          RoundedRectangle(cornerRadius: 16)
            .fill(.tint)
        }
        .foregroundStyle(.white)
    }

    if viewModel.servings.isNotEmpty {
      Button {
        Task {
          do {
            try await save()
            dismiss()
          } catch {
            self.viewModel.error = error
          }
        }
      } label: {
        Text("Log")
          .bold()
          .horizontallyCentered()
          .frame(height: 55)
          .background {
            RoundedRectangle(cornerRadius: 16)
              .fill(.tint)
          }
          .foregroundStyle(.white)
      }
    } else {
      Button {
        startScanToggle.toggle()
        Task {
          guard permissionManager.permissionState == .granted else {
            alertDetails = permissionManager.permissionAlert
            return
          }
          guard let image = await cameraManager.capture() else { return } // TODO: Throw error?

          viewModel.image = image
          await viewModel.performAIFoodLog(for: image)

          if viewModel.servings.isNotEmpty {
            scanResultsToggle.toggle()
          }
        }
      } label: {
        Text("Scan")
          .bold()
          .horizontallyCentered()
          .frame(height: 55)
          .background {
            RoundedRectangle(cornerRadius: 16)
              .fill(.tint)
          }
          .foregroundStyle(.white)
      }
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
