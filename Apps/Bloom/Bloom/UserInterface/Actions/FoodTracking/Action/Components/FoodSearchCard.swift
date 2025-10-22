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
  let onUploadNewFood: (FoodItem) -> Void
  let onFoodItemPicked: ((FoodItem) -> Void)?

  init(
    searchQuery: Binding<String>,
    toolbarMode: ToolbarMode,
    onSearch: @escaping (String) -> Void,
    onUploadNewFood: @escaping (FoodItem) -> Void,
    onFoodItemPicked: ((FoodItem) -> Void)? = nil
  ) {
    self._searchQuery = searchQuery
    self.toolbarMode = toolbarMode
    self.onSearch = onSearch
    self.onUploadNewFood = onUploadNewFood
    self.onFoodItemPicked = onFoodItemPicked
  }

  @FocusState private var isFocused: Bool

  @State private var didSearchToggle = false
  @State private var presentedSheet: AnyView?

  @AppStorage("FoodLoggingActionCardView.hasShownExplanation", store: .group) private var hasShownExplanation = false

  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        coreContentView
          .glassEffect(in: RoundedRectangle(cornerRadius: 40))
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
      }
    } else {
      coreContentView
        .background {
          RoundedRectangle(cornerRadius: 40)
            .fill(.background.secondary)
            .ignoresSafeArea(edges: .bottom)
            .overlay {
              RoundedRectangle(cornerRadius: 40)
                .stroke(.fill)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
  }
}

private extension FoodSearchCard {

  var coreContentView: some View {
    VStack {
      if !isFocused {
        switch toolbarMode {
        case .logTools:
          HStack {
            magicScanButton
            textFoodButton
            addFoodButton
          }
        case .pickerTools:
          HStack {
            barcodeScannerPickerButton
            Spacer()
          }
        case .noTools:
          EmptyView()
        }
      }
      searchTextField
    }
    .padding()
    .sheet($presentedSheet)
    .sensoryFeedback(.selection, trigger: isFocused)
    .animation(.easeInOut, value: isFocused)
    .animation(.easeInOut, value: searchQuery.isEmpty)
  }

  var magicScanButton: some View {
    FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Scan") {
      showMagicScan()
    }
  }

  var textFoodButton: some View {
    FoodSearchActionButton(symbol: .quoteBubble, title: "Text") {
      showTextFoodGenerationView()
    }
  }

  var addFoodButton: some View {
    FoodSearchActionButton(symbol: .plusViewfinder, title: "Upload") {
      showFoodUploadView()
    }
  }

  var barcodeScannerPickerButton: some View {
    FoodSearchActionButton(symbol: .barcodeViewfinder, title: "Scan") {
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

      TextField(
        "",
        text: $searchQuery,
        prompt: Text("Search for foods")
      )
      .focused($isFocused)
      .scrollDismissesKeyboard(.interactively)

      if searchQuery.isNotEmpty {
        Button {
          searchQuery = ""
          onSearch("")
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.white, .gray)
        }
        .buttonStyle(.plain)
        .transition(.scale)
      } else if isFocused {
        Button {
          isFocused = false
        } label: {
          Image(systemSymbol: .chevronDownCircleFill)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.white, .gray)
        }
        .buttonStyle(.plain)
        .transition(.scale)
      }
    }
    .submitLabel(.search)
    .sensoryFeedback(.impact, trigger: didSearchToggle)
    .onSubmit {
      performSearch()
    }
    .selectAllTextOnBeginEditing()
    .cardContainer()
//    .onChange(of: searchQuery) { oldValue, newValue in
//      guard shouldAutocomplete else { return }
//
//      viewModel.debounceAutocomplete(for: searchQuery)
//    }
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
      if hasShownExplanation {
        presentedSheet = AIFoodScannerView().asAny
      } else {
        presentedSheet = AIFoodScannerExplanationView {
          Task {
            await Delay(300)
            await MainActor.run {
              hasShownExplanation = true
              presentedSheet = AIFoodScannerView().asAny
            }
          }
        }.asAny
      }
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

  func showTextFoodGenerationView() {
    EntitledAction(presentedSheet: $presentedSheet) {
      presentedSheet = AIFoodTextGenerationView().asAny
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
