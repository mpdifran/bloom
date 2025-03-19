//
//  AIFoodScannerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import BloomModel
import AVFoundation

extension AIFoodScannerView {
  enum Mode: Equatable {
    case base
    case aiScanLoading
    case aiScanResults
  }
}

struct AIFoodScannerView: View {

  @State private var viewModel = ViewModel()

  @State private var startScanToggle = false
  @State private var isSwipingItem = false
  @State private var saveComplete = false
  @State private var errorToggle = false
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @FocusState private var focusedIndex: Int?

  @StateObject var permissionManager = CameraPermissionManager.shared

  @Environment(\.dismiss) private var dismiss

  @Namespace private var aiFoodScannerNamespace

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
  private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    NavigationStack {
      ZStack {
        switch viewModel.mode {
        case .aiScanResults:
          scrollContentView
        default:
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
        ToolbarItem(placement: .principal) {
          FoodItemLogPickerHeader()
        }
      }
    }
    .sensoryFeedback(.error, trigger: errorToggle)
    .sensoryFeedback(.impact, trigger: startScanToggle)
    .sensoryFeedback(.success, trigger: viewModel.scanResultsToggle)
    .sensoryFeedback(.error, trigger: viewModel.scanResultsErrorToggle)
    .sensoryFeedback(.success, trigger: saveComplete)
    .presentationCompactAdaptation(.fullScreenCover)
    .animation(.default, value: viewModel.servings)
    .animation(.default, value: viewModel.suggestedServings)
    .animation(.default, value: viewModel.image)
    .animation(.default, value: viewModel.mode)
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
    .sheet($presentedSheet)
    .alert(alertDetails: $alertDetails)
    .alert(error: $viewModel.error)
    .onChange(of: viewModel.error as? NSError) { oldValue, newValue in
      guard newValue != nil else { return }

      errorToggle.toggle()
    }
    .onChange(of: locationViewModel.country) { _, newValue in
      guard let country = newValue else { return }

      viewModel.country = country
    }
  }
}

private extension AIFoodScannerView {

  var fixedContentView: some View {
    VStack(spacing: 0) {
      if focusedIndex == nil {
        AICameraScannerView(
          cameraManager: viewModel.cameraManager,
          image: $viewModel.image
        )
        .fixedSize(horizontal: false, vertical: true)
        .matchedGeometryEffect(id: "aiCameraScannerView", in: aiFoodScannerNamespace)
      }

      switch viewModel.mode {
      case .base:
        if viewModel.suggestedServings.isNotEmpty || viewModel.servings.isNotEmpty || viewModel.unknownBarcodes.isNotEmpty {
          ScrollView {
            VStack {
              servingSections
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(isSwipingItem)
          }
        } else {
          instructionView
        }
      case .aiScanLoading:
        analyzingView
      case .aiScanResults:
        Spacer()
      }

      if focusedIndex != nil {
        textEditorButton
      } else if viewModel.servings.isNotEmpty {
        logFoodButton
      } else {
        scanFoodButton
      }
    }
    .padding()
  }

  var scrollContentView: some View {
    ScrollView {
      VStack {
        scannedItemHeader
        servingSections
      }
      .padding()
    }
    .scrollDisabled(isSwipingItem)
    .animation(.default, value: viewModel.servings)
    .animation(.default, value: viewModel.suggestedServings)
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

  var scannedItemHeader: some View {
    HStack(spacing: 20) {
      if let image = viewModel.image {
        AICameraRoundedImageView(image: image)
          .frame(square: 100)
          .matchedGeometryEffect(id: "aiCameraScannerView", in: aiFoodScannerNamespace)
      }

      VStack(alignment: .leading) {
        if let name = viewModel.scannedFoodName {
          Text(name)
            .font(.title2)
            .bold()
            .fontDesign(.rounded)
        }
      }

      Spacer(minLength: 0)
    }
  }

  var servingSections: some View {
    VStack {
      if viewModel.servings.isNotEmpty {
        SectionTitleView("\(viewModel.servings.count) \(viewModel.servings.count == 1 ? "Food Item" : "Food Items")")
          .padding(.horizontal)
        ForEachEnumerated(viewModel.servings) { (index, serving) in
          Swipeable(
            isSwipingItem: $isSwipingItem,
            actions: [
              SwipeAction(
                title: "Delete",
                symbol: .trash,
                tint: .mutedRed
              ) {
                viewModel.suggestedServings.insert(serving, at: 0)
                viewModel.servings.remove(at: index)
              }
            ]
          ) {
            Group {
              if viewModel.servings.count > index { // Fixes dumb bug where viewModel.servings is empty but we try and load a cell.
                AIScanFoodItemCell(foodItemServing: $viewModel.servings[index])
                  .focused($focusedIndex, equals: index)
                  .transition(.blurReplace)
                  .onTapGesture {
                    presentedSheet = FoodItemDetailsView(
                      foodItem: serving.foodItem,
                      existingFoodItemLog: nil,
                      mode: .viewOnly
                    ).asAny
                  }
              }
            }
          }
        }
      }

      if viewModel.suggestedServings.isNotEmpty {
        SectionTitleView("Suggestions")
          .padding(.horizontal)
        ForEachEnumerated(viewModel.suggestedServings) { (index, serving) in
          if viewModel.suggestedServings.count > index { // Fixes dumb bug where viewModel.servings is empty but we try and load a cell.
            AIScanFoodItemSuggetionCell(foodItemServing: serving) {
              viewModel.servings.append(serving)
              viewModel.suggestedServings.remove(at: index)
            }
            .transition(.blurReplace)
            .onTapGesture {
              presentedSheet = FoodItemDetailsView(
                foodItem: serving.foodItem,
                existingFoodItemLog: nil,
                mode: .viewOnly
              ).asAny
            }
          }
        }
      }

      if viewModel.unknownBarcodes.isNotEmpty {
        SectionTitleView("Barcodes")
          .padding(.horizontal)
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
  }

  var scanFoodButton: some View {
    Button {
      scanFoodItems()
    } label: {
      Text("Take a Photo")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .disabled(viewModel.mode != .base)
  }

  var logFoodButton: some View {
    AsyncButton {
      try await save()
      dismiss()
    } label: {
      Group {
        if viewModel.servings.isNotEmpty {
          Text("Log \(viewModel.servings.count) \(viewModel.servings.count == 1 ? "Food Item" : "Food Items")")
        } else {
          Text("Log")
        }
      }
      .horizontallyCentered()
    }
    .buttonStyle(.primary)
    .disabled(viewModel.servings.isEmpty)
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

      HStack {
        Spacer()
        Image(.soup)
          .overlay {
            CameraReticuleShapeView(lineWidth: 6, cornerRadius: 15)
          }
        Spacer()
        Image(.barcodePackaging)
          .overlay {
            CameraReticuleShapeView(lineWidth: 6, cornerRadius: 5)
              .frame(width: 45, height: 40)
              .padding(.bottom, 12)
              .padding(.trailing, 12)
              .zStackAlignment(.bottomTrailing)
          }

        Spacer()
      }
      .padding(.vertical)

      Text("Hold up a barcode to scan, or take a photo to estimate your whole plate.")
        .font(.title3)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)

      Spacer()
    }
  }

  var analyzingView: some View {
    VStack {
      Spacer()
      ProgressView()
        .progressViewStyle(.circular)
//      CircularSpinnerView() // TODO: Figure out why this animation dies during loading, but the above spinner doesn't
//        .foregroundStyle(.tint)
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
          Image(systemSymbol: .arrowCounterclockwise)
            .bold()
        }
        .horizontalAlignment(.trailing)
      }
    Divider()
  }
}

private extension AIFoodScannerView {

  func scanFoodItems() {
    startScanToggle.toggle()

    guard permissionManager.permissionState == .granted else {
      alertDetails = permissionManager.permissionAlert
      return
    }

    Task {
      await viewModel.takePhoto()
    }
  }

  func save() async throws {
    try await nutritionViewModel.logMeal(
      name: viewModel.scannedFoodName ?? "My Scanned Meal",
      image: viewModel.image,
      numberOfServings: 1,
      foodItemServings: viewModel.servings,
      date: nutritionViewModel.date,
      meal: nutritionViewModel.suggestedMeal
    )

    saveComplete.toggle()
    SoundPlayer.playLogHealthData()
  }
}

#Preview {
  PreviewEnvironment {
    AIFoodScannerView()
  }
}
