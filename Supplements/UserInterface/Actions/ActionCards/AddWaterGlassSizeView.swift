//
//  AddWaterGlassSizeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI
import AppUI

struct AddWaterGlassSizeView: View {

    let onAdd: (WaterGlassSizeModel) -> Void

    @State private var name: String = ""
    @State private var quantityValue: Double = 0

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack {
                    LabeledContent("Name") {
                        TextField("", text: $name, prompt: Text("My Waterbottle"))
                            .fontDesign(.rounded)
                            .bold()
                            .multilineTextAlignment(.trailing)
                    }

                    Divider()

                    LabeledContent("Quantity") {
                        HStack {

                            Spacer()
                            TextField("", value: $quantityValue, formatter: NumberFormatter.noDecimalPlaces)
                                .selectAllTextOnBeginEditing()
                                .focused($isFocused)
                            Text("mL")
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 200)
                        .fontDesign(.rounded)
                        .keyboardType(.decimalPad)
                        .bold()
                        .multilineTextAlignment(.trailing)
                    }
                }
                .cardContainer(fill: .background.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Add Glass Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .shelf {
                ProminentButton("Add") {
                    let size = WaterGlassSizeModel(
                        name: name,
                        quantityValue: quantityValue,
                        unit: .literUnit(with: .milli)
                    )
                    onAdd(size)
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(25)
        .tint(.mutedBlue)
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
                AddWaterGlassSizeView { size in

                }
            }
        }
    }
    return PreviewView()
}
