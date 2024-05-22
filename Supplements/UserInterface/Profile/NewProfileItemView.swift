//
//  NewProfileItemView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-22.
//

import SwiftUI

struct NewProfileItemView: View {
    let itemName: String
    let systemImageName: String
    let values: [String]
    let newValue: (String) -> Void

    @State private var newItemText = ""
    @FocusState private var isTextFieldFocused

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Suggestions") {
                    ForEach(filteredValues, id: \.self) { value in
                        Text(value)
                            .bold()
                            .fontDesign(.rounded)
                            .onTapGesture {
                                newItemText = value
                            }
                    }
                }
            }
            .navigationTitle("Add \(itemName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        newValue(newItemText.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .bold()
                    .disabled(newItemText.isEmpty)
                }
            }
            .shelf {
                TextActionBar(
                    searchText: $newItemText,
                    prompt: "Add \(itemName)",
                    systemImage: systemImageName,
                    submitLabel: .done
                )
                .focused($isTextFieldFocused)
                .onSubmit {
                    newValue(newItemText.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

private extension NewProfileItemView {

    var filteredValues: [String] {
        let trimmedSearchText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedSearchText.isNotEmpty else {
            return values
        }

        return values.filter { value in
            value.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }
}

#Preview {
    NewProfileItemView(
        itemName: "Supplement",
        systemImageName: "cross.vial",
        values: ["Vitamin C", "Vitamin D"]
    ) { _ in }
}
