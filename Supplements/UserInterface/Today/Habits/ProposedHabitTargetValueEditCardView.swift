//
//  ProposedHabitTargetValueEditCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import AppUI
import HealthKit

struct ProposedHabitTargetValueEditCardView: View {
    @Binding var proposedHabit: ProposedHabit
    @State private var value: Double

    init(proposedHabit: Binding<ProposedHabit>) {
        self._proposedHabit = proposedHabit
        self._value = State(initialValue: proposedHabit.wrappedValue.value)
    }

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                HStack {
                    TextField("", value: $value, formatter: proposedHabit.targetMetric.preferredFormatter)
                        .selectAllTextOnBeginEditing()
                        .focused($isFocused)
                    Text(proposedHabit.unitString)
                }
                .fontDesign(.rounded)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.trailing)
                .padding()
                .padding(.horizontal, 30)

                if let previousQuantity = proposedHabit.displayPreviousQuantity {
                    Text("Previously \(previousQuantity)")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .background {
                Rectangle()
                    .fill(.tint.tertiary)
                    .ignoresSafeArea()
            }
            .navigationTitle(proposedHabit.targetMetric.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .shelf {
                ProminentButton("Save") {
                    proposedHabit.value = value
                    proposedHabit.hasUserEdited = true
                    dismiss()
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationCornerRadius(25)
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true
        @State private var proposedHabit = ProposedHabit(
            targetMetric: .stepCount,
            value: 3000,
            suggestedValue: 3000,
            previousValue: 2000,
            unitString: HKUnit.count().unitString,
            vitalKind: .cardioFitness,
            context: ""
        )

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                ProposedHabitTargetValueEditCardView(proposedHabit: $proposedHabit)
            }
        }
    }
    return PreviewView()
}
