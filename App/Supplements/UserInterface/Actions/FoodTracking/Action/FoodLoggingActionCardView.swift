//
//  FoodLoggingActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI
import AppUI
import DataContainer

struct FoodLoggingActionCardView: View {

    @Bindable private var viewModel = ViewModel()

    @State private var searchQuery = ""
    @State private var shouldAutocomplete = true
    @State private var didSearchToggle = false
    @State private var presentedSheet: AnyView?

    @State private var showAllInSection = [Int : Bool]()

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool

    private let nutritionViewModel = NutritionTrackingViewModel.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainView
                suggestionsBarView
                foodSearchTextBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    mealPicker
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .sheet($presentedSheet)
        .presentationDetents([.large])
        .presentationCornerRadius(25)
        .presentationCompactAdaptation(.fullScreenCover)
        .alert(error: $viewModel.error)
        .tint(.mutedGreen)
    }
}

private extension FoodLoggingActionCardView {

    var mealPicker: some View {
        Menu {
            ForEach(FoodItemLog.Meal.allCases, id: \.self) { meal in
                Button(meal.name) {
                    nutritionViewModel.suggestedMeal = meal
                }
            }
        } label: {
            HStack {
                Text(nutritionViewModel.suggestedMeal.name)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .bold()
        }
    }

    @ViewBuilder
    var mainView: some View {
        if viewModel.isSearching {
            searchingView
        } else if let results = viewModel.results {
            if results.isNotEmpty {
                resultsView(results: results)
            } else {
                noContentView
            }
        } else {
            Spacer()
        }
    }

    var searchingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.secondary)
            Text("Looking up foods...")
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    func resultsView(results: [FoodItemSection]) -> some View {
        ScrollView {
            LazyVStack {
                ForEachEnumerated(results) { (sectionIndex, section) in
                    SectionTitleView(section.title)
                        .padding(.horizontal)

                    ForEachEnumerated(section.foodItems) { index, food in
                        if index < 3 || showAllInSection[sectionIndex] == true {
                            FoodItemCell(food: food)
                                .id(food.id)
                                .transition(.blurReplace)
                                .onTapGesture {
                                    presentedSheet = FoodItemDetailsView(
                                        foodItem: food,
                                        existingFoodItemLog: nil
                                    ).asAny
                                }
                        }
                    }

                    if showAllInSection[sectionIndex] != true && section.foodItems.count > 3 {
                        Button {
                            showAllInSection[sectionIndex] = true
                        } label: {
                            Text("Show All")
                                .padding(.vertical, 6)
                                .horizontallyCentered()
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .listStyle(.plain)
        .animation(.bouncy, value: viewModel.results)
        .animation(.bouncy, value: showAllInSection)
    }

    var noContentView: some View {
        ContentUnavailableView("No Results", systemImage: "exclamationmark.magnifyingglass")
            .foregroundStyle(.secondary)
    }

    var suggestionsBarView: some View {
        ScrollView(.horizontal) {
            HStack {
                if viewModel.autocomplete.isNotEmpty {
                    ForEachEnumerated(viewModel.autocomplete) { (index, autocomplete) in
                        FoodSearchAutocompleteCell(query: autocomplete)
                            .transition(.scale)
                            .onTapGesture {
                                shouldAutocomplete = false
                                searchQuery = autocomplete
                                performSearch()
                                Delay(100) {
                                    shouldAutocomplete = true
                                }
                            }
                    }
                } else if searchQuery.isEmpty {
                    FoodSearchToolCell(title: "AI Scan", systemImage: "sparkles")
                        .onTapGesture {
                            presentedSheet = AIFoodScannerView().asAny
                        }
                    FoodSearchToolCell(title: "Scan Barcode", systemImage: "barcode.viewfinder")
                        .onTapGesture {
                            presentedSheet = FoodBarcodeScannerView { barcode in
                                isFocused = false
                                Task {
                                    await viewModel.performBarcodeSearch(for: barcode)
                                }
                            }.asAny
                        }
                    FoodSearchToolCell(title: "Add New Food", systemImage: "plus.viewfinder")
                        .onTapGesture {
                            presentedSheet = FoodUploadScannerView().asAny
                        }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .animation(.bouncy, value: viewModel.autocomplete)
    }

    var foodSearchTextBar: some View {
        HStack {
            TextField(
                "",
                text: $searchQuery,
                prompt: Text("What did you eat?")
            )
            .padding()
            .onChange(of: searchQuery) { oldValue, newValue in
                guard shouldAutocomplete else { return }

                viewModel.debounceAutocomplete(for: searchQuery)
            }

            Button {
                performSearch()
            } label: {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white, .tint)
            }
            .sensoryFeedback(.impact, trigger: didSearchToggle)
        }
        .focused($isFocused)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(.background.secondary)
                .onTapGesture {
                    isFocused = true
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private extension FoodLoggingActionCardView {

    func performSearch() {
        didSearchToggle.toggle()
        showAllInSection.removeAll()
        isFocused = false
        Task {
            await viewModel.performSearch(for: searchQuery)
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                FoodLoggingActionCardView()
            }
        }
    }
    return PreviewView()
}
