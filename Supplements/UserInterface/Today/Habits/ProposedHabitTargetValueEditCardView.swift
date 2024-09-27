//
//  ProposedHabitTargetValueEditCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import AppUI
import HealthKit
import SwiftData

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

                if proposedHabit.shouldShowSuggestedValue {
                    Text("Recommended \(proposedHabit.displaySuggestedValue)")
                        .bold()
                }
                if let previousQuantity = proposedHabit.displayPreviousQuantity {
                    Text("Previously \(previousQuantity)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
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
            habitID: nil,
            targetMetric: .stepCount,
            value: 3000,
            suggestedValue: 5000,
            previousValue: 2000,
            unitString: HKUnit.count().unitString,
            vitalKind: .heartHealth,
            context: "",
            hasUserEdited: true
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
