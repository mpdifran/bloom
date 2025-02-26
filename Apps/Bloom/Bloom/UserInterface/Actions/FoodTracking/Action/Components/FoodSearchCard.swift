//
//  FoodSearchCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SwiftUI
import BloomModel

struct FoodSearchCard: View {

  @Binding var searchQuery: String
  let onSearch: (String) -> Void
  let onUploadNewFood: (FoodItem) -> Void

  init(
    searchQuery: Binding<String>,
    onSearch: @escaping (String) -> Void,
    onUploadNewFood: @escaping (FoodItem) -> Void
  ) {
    self._searchQuery = searchQuery
    self.onSearch = onSearch
    self.onUploadNewFood = onUploadNewFood
  }

  @FocusState private var isFocused: Bool

  @State private var didSearchToggle = false
  @State private var presentedSheet: AnyView?

  @AppStorage("FoodLoggingActionCardView.hasShownExplanation", store: .group) private var hasShownExplanation = false

  var body: some View {
    VStack {
      if !isFocused {
        HStack {
          magicScanButton
          addFoodButton
        }
      }
      searchTextField
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.background.secondary)
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: .text.opacity(0.1), radius: 20)
        .overlay {
          RoundedRectangle(cornerRadius: 40)
            .stroke(.fill)
            .ignoresSafeArea(edges: .bottom)
        }
    }
    .sheet($presentedSheet)
    .sensoryFeedback(.selection, trigger: isFocused)
    .animation(.easeInOut, value: isFocused)
    .animation(.easeInOut, value: searchQuery.isEmpty)
  }
}

private extension FoodSearchCard {

  var magicScanButton: some View {
    Button {
      showMagicScan()
    } label: {
      HStack {
        Image(systemName: "viewfinder")
          .foregroundStyle(.tint)
        Text("AI Scan")
          .foregroundStyle(.primary)
      }
      .horizontallyCentered()
      .cardContainer()
    }
    .buttonStyle(.plain)
    .bold()
  }

  var addFoodButton: some View {
    Button {
      showFoodUploadView()
    } label: {
      HStack {
        Image(systemName: "plus.viewfinder")
          .foregroundStyle(.tint)
        Text("Add New Food")
          .foregroundStyle(.primary)
      }
      .horizontallyCentered()
      .cardContainer()
    }
    .buttonStyle(.plain)
    .bold()
  }

  var quickAddButton: some View {
    Button {

    } label: {
      HStack {
        Image(systemName: "plus")
          .foregroundStyle(.tint)
        Text("Quick Add")
          .foregroundStyle(.primary)
      }
      .horizontallyCentered()
      .cardContainer()
    }
    .buttonStyle(.plain)
    .bold()
  }

  var searchTextField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
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
          Image(systemName: "xmark.circle.fill")
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
          Image(systemName: "chevron.down.circle.fill")
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

  func showFoodUploadView() {
    presentedSheet = FoodUploadScannerView() { foodItem in
      onUploadNewFood(foodItem)
    }.asAny
  }
}

#Preview {
  @Previewable @State var searchQuery = ""

  VStack {
    Spacer()
    Text("Hello World")
    Spacer()
  }
  .horizontallyCentered()
  .groupedBackground()
  .safeAreaInset(edge: .bottom) {
    FoodSearchCard(searchQuery: $searchQuery) { searchQuery in

    } onUploadNewFood: { foodItem in

    }
    .tint(.mutedPurple)
  }
}
