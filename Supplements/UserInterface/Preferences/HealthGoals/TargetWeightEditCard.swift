//
//  TargetWeightEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-07.
//

import SwiftUI

struct TargetWeightEditCard: View {

    @State private var weight: Double

    init() {
        self._weight = State(initialValue: HealthManager.shared.targetWeight)
    }

    @FocusState private var isFocused: Bool
    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ActionCardView(
            title: "Target Weight"
        ) { (_) in
            saveTargetWeight()
        } content: { (_, handleSave) in
            VStack {
                Spacer()

                HStack {
                    TextField("", value: $weight, formatter: NumberFormatter.oneDecimalPlace)
                        .selectAllTextOnBeginEditing()
                        .focused($isFocused)
                    Text("lbs")
                }
                .frame(width: 200)
                .fontDesign(.rounded)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.trailing)

                Spacer()
            }
        }
        .tint(.mutedIndigo)
        .onAppear {
            isFocused = true
        }
    }
}

private extension TargetWeightEditCard {

    func saveTargetWeight() -> Bool {
        HealthManager.shared.targetWeight = weight
        return true
    }
}

#Preview {
    TargetWeightEditCard()
}
