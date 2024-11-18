//
//  FoodLoggingActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import SwiftUI
import AppUI

struct FoodLoggingActionCardView: View {

    @Bindable private var viewModel = ViewModel()

    @State private var searchQuery = ""
    @State private var shouldAutocomplete = true
    @State private var didSearchToggle = false
    @State private var presentedSheet: AnyView?

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                resultsView
                suggestionsBarView
                foodSearchTextBar
            }
//            .navigationTitle("Log Food")
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
            .onAppear {
                isFocused = true
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
            ForEach(FoodLoggingActionCardView.ViewModel.Meal.allCases, id: \.self) { meal in
                Button(meal.name) {
                    viewModel.meal = meal
                }
            }
        } label: {
            HStack {
                Text(viewModel.meal.name)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .bold()
        }
    }

    @ViewBuilder
    var resultsView: some View {
        if viewModel.isSearching {
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
        } else if let results = viewModel.results {
            if results.isNotEmpty {
                ScrollView {
                    VStack {
                        ForEach(results) { section in
                            Section(section.title) {
                                ForEach(section.foodItems) { food in
                                    FoodItemCell(food: food)
                                        .transition(.scale)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .animation(.bouncy, value: viewModel.results)
            } else {
                ContentUnavailableView("No Results", systemImage: "exclamationmark.magnifyingglass")
                    .foregroundStyle(.secondary)
            }
        } else {
            Spacer()
        }
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
                    FoodSearchToolCell(title: "AI Photo", systemImage: "sparkles")
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
