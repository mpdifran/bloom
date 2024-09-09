//
//  EditGoalTargetView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import SwiftUI
import HealthKit

struct EditGoalTargetView: View {

    @Binding var goal: GoalModel

    @State private var targetDailyValue: Double

    @Environment(\.dismiss) private var dismiss

    init(goal: Binding<GoalModel>) {
        self._goal = goal
        self._targetDailyValue = State(initialValue: goal.wrappedValue.metric.dailyValue)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    TextField("", value: $targetDailyValue, formatter: NumberFormatter.noDecimalPlaces)
                    Text(goal.metric.unitString)
                }
                .frame(width: 240)
                .fontDesign(.rounded)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.trailing)
                Spacer()
            }
            .navigationTitle("Change Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Cancel")
                    })
                }
            }
            .shelf {
                Button {
                    goal = goal.duplicate(with: targetDailyValue)
                    dismiss()
                } label: {
                    Text("Save")
                        .horizontallyCentered()
                }
                .buttonStyle(.tertiary)
            }
        }
        .presentationDetents([.height(300)])
        .presentationCornerRadius(25)
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true
        @State private var goal = GoalModel(
            title: "Walking + Running Distance",
            systemImage: "figure.walk",
            summary: "An easy way to improve your activity level is to incorporate more walking and running into your week.",
            dueDate: .now.addingTimeInterval(
                60 * 60 * 24 * 3
            ),
            metric: .init(
                value: 25,
                unit: HKUnit.meterUnit(
                    with: .kilo
                ),
                measurement: .walkRunDistance
            ),
            vitalKind: .cardioFitness
        )

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                EditGoalTargetView(goal: $goal)
            }
        }
    }
    return PreviewView()
}
