//
//  VitalPickerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-04.
//

import SwiftUI
import DataContainer
import AppUI

struct VitalPickerView: View {
    let excluding: [VitalModel.Kind]
    let onSelect: (VitalModel) -> Void

    private let vitalsViewModel = VitalsViewModel.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEachEnumerated(vitalsViewModel.allVitals) { (index, vital) in
                        if !excluding.contains(vital.id) {
                            MiniVitalCell(vital: vital)
                                .onTapGesture {
                                    onSelect(vital)
                                    dismiss()
                                }
                                .transition(.scale)
                                .animation(
                                    .bouncy
                                        .delay(Double(100 * index)),
                                    value: index
                                )
                        }
                    }
                }
                .horizontalAlignment(.leading)
                .padding()
            }
            .navigationTitle("Pick a Vital")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VitalPickerView(excluding: [.bodyComposition]) { (_) in
        
    }
}
