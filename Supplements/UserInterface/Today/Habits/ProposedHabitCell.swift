//
//  ProposedHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import HealthKit

struct ProposedHabitCell: View {
    @Binding var proposedHabit: ProposedHabit
    let includeActions: Bool

    init(
        proposedHabit: Binding<ProposedHabit>,
        includeActions: Bool = true
    ) {
        self._proposedHabit = proposedHabit
        self.includeActions = includeActions
    }

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    @State private var presentedSheet: AnyView?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack {
                HStack {
                    Image(systemName: proposedHabit.targetMetric.systemImage)
                        .font(.title)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading) {
                        if let vitalKind = proposedHabit.vitalKind {
                            Label(vitalKind.name, systemImage: vitalKind.systemImage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(proposedHabit.targetMetric.name)
                            .bold()
                    }

                    Spacer(minLength: 0)

                    VStack {
                        if let previousQuantity = proposedHabit.displayPreviousQuantity, proposedHabit.shouldShowPreviousQuantity {
                            Text("\(previousQuantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            Image(systemName: "arrow.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if proposedHabit.isNewHabit {
                            Text("NEW")
                                .foregroundStyle(.mutedRed)
                                .bold()
                                .font(.caption)
                        }

                        Text(proposedHabit.displayQuantity)
                            .font(.title3)
                            .fontDesign(.rounded)
                            .bold()
                            .foregroundStyle(.tint)
                            .contentTransition(.numericText(value: proposedHabit.value))
                            .animation(.default, value: proposedHabit.value)
                    }
                }

                if proposedHabit.shouldShowSuggestedValue {
                    Divider()
                    
                    HStack {
                        Text("Recommended")
                        
                        Spacer()
                        
                        Text(proposedHabit.displaySuggestedValue)
                            .foregroundStyle(.tint)
                            .fontDesign(.rounded)
                            .bold()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            .cardContainer(stroke: .tint)

            if includeActions {
                if habitsViewModel.alternateTargetMetrics(for: proposedHabit).isNotEmpty {
                    Menu {
                        ForEach(habitsViewModel.alternateTargetMetrics(for: proposedHabit)) { alternativeTargetMetric in
                            Button {
                                Task {
                                    proposedHabit = await habitsViewModel.generateProposedHabit(
                                        for: alternativeTargetMetric,
                                        vitalKind: proposedHabit.vitalKind
                                    )
                                }
                            } label: {
                                Label(alternativeTargetMetric.name, systemImage: alternativeTargetMetric.systemImage)
                            }
                        }
                    } label: {
                        LabeledContent("Change Habit") {
                            Image(systemName: "trophy")
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding()
                    
                    Divider()
                }

                Button {
                    presentedSheet = ProposedHabitTargetValueEditCardView(proposedHabit: $proposedHabit).tint(proposedHabit.targetMetric.color).asAny
                } label: {
                    LabeledContent("Change Value") {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(.tint)
                    }
                }
                .padding()

//                Divider()
//
//                Menu {
//                    Text("Test")
//                } label: {
//                    LabeledContent("Change Vital") {
//                        Image(systemName: "bolt.heart")
//                            .foregroundStyle(.tint)
//                    }
//                }
//                .padding()
//                
//                Divider()
//
//                Menu {
//                    Text("Test")
//                } label: {
//                    LabeledContent("Change Habit") {
//                        Image(systemName: "trophy")
//                            .foregroundStyle(.tint)
//                    }
//                }
//                .padding()
            }
        }
        .cardContainer(fill: .tint.tertiary, includePadding: false)
        .tint(proposedHabit.targetMetric.color)
        .sheet($presentedSheet)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProposedHabitCell(
                proposedHabit: .constant(.init(
                    habitID: nil,
                    targetMetric: .waterIntake,
                    value: 500,
                    suggestedValue: 800,
                    previousValue: 250,
                    unitString: HKUnit.literUnit(with: .milli).unitString,
                    vitalKind: .nutrition,
                    context: "Water can keep you hydrated.",
                    hasUserEdited: true
                ))
            )
            ProposedHabitCell(
                proposedHabit: .constant(.init(
                    habitID: nil,
                    targetMetric: .walkingRunningDistance,
                    value: 5,
                    suggestedValue: 5,
                    previousValue: 5,
                    unitString: HKUnit.meterUnit(with: .kilo).unitString,
                    vitalKind: .cardioFitness,
                    context: "You should run more.",
                    hasUserEdited: true
                ))
            )
            ProposedHabitCell(
                proposedHabit: .constant(.init(
                    habitID: nil,
                    targetMetric: .timeInDaylight,
                    value: 30,
                    suggestedValue: 30,
                    previousValue: nil,
                    unitString: HKUnit.minute().unitString,
                    vitalKind: .sleepQuality,
                    context: "Get out in the sun!",
                    hasUserEdited: false
                ))
            )
        }
        .padding()
    }
    .groupedBackground()
}
