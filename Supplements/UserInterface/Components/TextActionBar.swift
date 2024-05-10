//
//  TextActionBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct TextActionBar: View {
    @Binding var searchText: String
    let prompt: String
    let systemImage: String
    let axis: Axis
    let submitLabel: SubmitLabel
    let onSubmit: () -> Void

    init(
        searchText: Binding<String>,
        prompt: String,
        systemImage: String,
        axis: Axis = .horizontal,
        submitLabel: SubmitLabel = .search,
        onSubmit: @escaping () -> Void = { }
    ) {
        self._searchText = searchText
        self.prompt = prompt
        self.systemImage = systemImage
        self.axis = axis
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .bold()
                .fontDesign(.rounded)

            TextField(
                "",
                text: $searchText,
                prompt: Text(prompt),
                axis: axis
            )
            .focused($isSearchFieldFocused)
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
            .onChange(of: searchText) { oldValue, newValue in
                guard axis == .vertical else { return }

                if let newLineIndex = newValue.lastIndex(of: "\n") {
                    searchText.remove(at: newLineIndex)
                    isSearchFieldFocused = false
                    onSubmit()
                }
            }
        }
        .padding(.vertical, 8)
        .roundedBackground()
    }
}

#Preview {
    TextActionBar(
        searchText: .constant(""),
        prompt: "What would you like to search for?",
        systemImage: "magnifyingglass"
    )
}
