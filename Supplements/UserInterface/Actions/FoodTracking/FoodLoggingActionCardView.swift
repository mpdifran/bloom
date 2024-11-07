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

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List(viewModel.results) { result in
                    USDAFoodCell(food: result)
                }

                ScrollView(.horizontal) {
                    HStack {
                        ForEachEnumerated(viewModel.autocomplete) { (index, autocomplete) in
                            FoodSearchAutocompleteCell(query: autocomplete)
                                .transition(.blurReplace)
                                .onTapGesture {
                                    shouldAutocomplete = false
                                    searchQuery = autocomplete
                                    performSearch()
                                    Delay(100) {
                                        shouldAutocomplete = true
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .animation(.bouncy, value: viewModel.autocomplete)

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
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(25)
        .alert(error: $viewModel.error)
        .tint(.mutedGreen)
    }
}

private extension FoodLoggingActionCardView {

    func performSearch() {
        viewModel.performSearch(for: searchQuery)
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
