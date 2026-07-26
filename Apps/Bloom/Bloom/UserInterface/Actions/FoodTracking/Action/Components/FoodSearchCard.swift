//
//  FoodSearchCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SFSafeSymbols
import SwiftUI
import BloomModel
import BloomFoundation
import DataContainer

extension FoodSearchCard {
  enum ToolbarMode {
    case logTools
    case pickerTools
    case noTools
  }
}

struct FoodSearchCard: View {

  @Binding var searchQuery: String
  let toolbarMode: ToolbarMode
  let onSearch: (String) -> Void
  let onTextChange: ((String) -> Void)?
  let onUploadNewFood: (FoodItem) -> Void
  let onFoodItemPicked: ((FoodItem) -> Void)?
  let performDismiss: (() -> Void)?

  init(
    searchQuery: Binding<String>,
    toolbarMode: ToolbarMode,
    onSearch: @escaping (String) -> Void,
    onTextChange: ((String) -> Void)? = nil,
    onUploadNewFood: @escaping (FoodItem) -> Void,
    onFoodItemPicked: ((FoodItem) -> Void)? = nil,
    performDismiss: (() -> Void)? = nil
  ) {
    self._searchQuery = searchQuery
    self.toolbarMode = toolbarMode
    self.onSearch = onSearch
    self.onTextChange = onTextChange
    self.onUploadNewFood = onUploadNewFood
    self.onFoodItemPicked = onFoodItemPicked
    self.performDismiss = performDismiss
  }

  @FocusState private var isFocused: Bool

  @State private var didSearchToggle = false
  @State private var presentedSheet: AnyView?

  var body: some View {
    Group {
        GlassEffectContainer {
          glassContentView
        }
    }
    .sheet($presentedSheet)
    .sensoryFeedback(.selection, trigger: isFocused)
    .animation(.easeInOut, value: isFocused)
    .animation(.easeInOut, value: searchQuery.isEmpty)
    .onChange(of: searchQuery) { _, newValue in
      onTextChange?(newValue)
    }
  }
}

private extension FoodSearchCard {

  var glassContentView: some View {
    VStack(spacing: 8) {
      if !isFocused {
        ScrollView(.horizontal) {
          HStack {
            switch toolbarMode {
            case .logTools:
              barcodeScanButton
                .transition(.scale)
              magicScanButton
                .transition(.scale)
              textFoodButton
                .transition(.scale)
            case .pickerTools:
              barcodeScannerPickerButton
                .transition(.scale)
            case .noTools:
              EmptyView()
            }
          }
          .scrollTargetLayout()
          .padding(.horizontal, 8)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
      }

      searchTextField
        .glassEffect(in: Capsule())
        .selectable()
        .padding(.horizontal, 8)
        .padding(.bottom)
    }
    .animation(.default, value: isFocused)
  }

  var barcodeScanButton: some View {
    FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Barcode Scan") {
      showBarcodeScanner()
    }
  }

  var magicScanButton: some View {
    FoodSearchActionButton(symbol: .cameraViewfinder, title: "Magic Scan") {
      showMagicScan()
    }
  }

  var textFoodButton: some View {
    FoodSearchActionButton(symbol: .microphoneFill, title: "Voice Logger") {
      showVoiceLogger()
    }
  }

  var barcodeScannerPickerButton: some View {
    FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Barcode Scan") {
      showBarcodeScannerPicker()
    }
  }

  var quickAddButton: some View {
    FoodSearchActionButton(symbol: .plus, title: "Quick Add") {

    }
  }

  var searchTextField: some View {
    HStack {
      Image(systemSymbol: .magnifyingglass)
        .foregroundStyle(.tint)
        .font(.title3)
        .padding(.leading)

      TextField(
        "",
        text: $searchQuery,
        prompt: Text("Search or Describe Food")
      )
      .focused($isFocused)
      .scrollDismissesKeyboard(.interactively)
      .padding(.vertical)

      if searchQuery.isNotEmpty {
        Button {
          withAnimation {
            searchQuery = ""
            onSearch("")
          }
        } label: {
            Image(systemSymbol: .xmarkCircleFill)
              .font(.system(size: 22))
              .fontDesign(.rounded)
              .foregroundStyle(.white, .fill)
        }
        .frame(square: 50)
        .buttonStyle(.plain)
        .transition(.scale)
        .padding(.trailing, 6)
      } else if isFocused {
        Button {
          withAnimation {
            isFocused = false
          }
        } label: {
            Image(systemSymbol: .chevronDownCircleFill)
              .font(.system(size: 22))
              .fontDesign(.rounded)
              .bold()
              .foregroundStyle(.white, .fill)

        }
        .frame(square: 50)
        .buttonStyle(.plain)
        .transition(.scale)
        .padding(.trailing, 6)
      }
    }
    .submitLabel(.search)
    .sensoryFeedback(.impact, trigger: didSearchToggle)
    .onSubmit {
      performSearch()
    }
    .selectAllTextOnBeginEditing()
  }
}

private extension FoodSearchCard {

  func performSearch() {
    didSearchToggle.toggle()
    isFocused = false
    onSearch(searchQuery)
  }

  func showMagicScan() {
    EntitledAction(presentedSheet: $presentedSheet) {
      presentedSheet = MagicScannerCameraView(performDismiss: performDismiss).asAny
    }
  }

  func showFoodUploadView() {
    presentedSheet = FoodUploadScannerView() { foodItem in
      onUploadNewFood(foodItem)
    }.asAny
  }

  func showBarcodeScannerPicker() {
    presentedSheet = BarcodeScannerPickerView(selectFoodItem: { foodItem in
      onFoodItemPicked?(foodItem)
    }).asAny
  }

  func showBarcodeScanner() {
    presentedSheet = BarcodeScannerView().asAny
  }

  func showVoiceLogger() {
    EntitledAction(presentedSheet: $presentedSheet) {
      presentedSheet = VoiceLoggerView(performDismiss: performDismiss).asAny
    }
  }
}

#Preview("Log Tools") {
  @Previewable @State var searchQuery = ""

  PreviewEnvironment {
    VStack {
      Spacer()
      Text("Hello World")
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
    .safeAreaInset(edge: .bottom) {
      FoodSearchCard(searchQuery: $searchQuery, toolbarMode: .logTools) { searchQuery in

      } onUploadNewFood: { foodItem in

      }
    }
  }
}

#Preview("Picker Tools") {
  @Previewable @State var searchQuery = ""

  PreviewEnvironment {
    VStack {
      Spacer()
      Text("Hello World")
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
    .safeAreaInset(edge: .bottom) {
      FoodSearchCard(searchQuery: $searchQuery, toolbarMode: .pickerTools) { searchQuery in

      } onUploadNewFood: { foodItem in

      }
    }
  }
}

#Preview("No Tools") {
  @Previewable @State var searchQuery = ""

  PreviewEnvironment {
    VStack {
      Spacer()
      Text("Hello World")
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
    .safeAreaInset(edge: .bottom) {
      FoodSearchCard(searchQuery: $searchQuery, toolbarMode: .noTools) { searchQuery in

      } onUploadNewFood: { foodItem in

      }
    }
  }
}
