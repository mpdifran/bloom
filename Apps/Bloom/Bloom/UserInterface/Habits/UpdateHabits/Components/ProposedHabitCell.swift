//
//  ProposedHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import HealthKit
import DataContainer

struct ProposedHabitCell: View {
  @Binding var proposedHabit: ProposedGoal
  let includeActions: Bool

  init(
    proposedHabit: Binding<ProposedGoal>,
    includeActions: Bool = true
  ) {
    self._proposedHabit = proposedHabit
    self.includeActions = includeActions
  }

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  @State private var alternateTargetMetrics = [TargetMetric]()
  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack {
        habitContentView

        if proposedHabit.shouldShowSuggestedValue {
          Divider()
          recommendedValueDisplayView
        }
      }
      .cardContainer(fill: .background.secondary)
      .padding(4)

      if includeActions {
        if let context = proposedHabit.context, context.isNotEmpty {
          Text(context)
            .foregroundStyle(.white)
            .bold()
            .fixedSize(horizontal: false, vertical: true)
            .padding()

          Divider()
        }

        if alternateTargetMetrics.isNotEmpty {
          alternateTargetMetricMenu
          Divider()
        }

        if proposedHabit.shouldShowSuggestedValue {
          setRecommendedValueButton
          Divider()
        }

        changeValueButton

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
    .cardContainer(fill: .tint, includePadding: false, cornerRadius: 30)
    .animation(.default, value: proposedHabit.value)
    .tint(proposedHabit.targetMetric.color)
    .sheet($presentedSheet)
    .task {
      self.alternateTargetMetrics = await habitsViewModel.alternateTargetMetrics(for: proposedHabit)
    }
  }
}

private extension ProposedHabitCell {

  var habitContentView: some View {
    HStack {
      Image(systemName: proposedHabit.targetMetric.systemImage)
        .font(.title)
        .foregroundStyle(.tint)

      VStack(alignment: .leading) {
        Text(proposedHabit.targetMetric.name)
          .bold()

        if let vitalKind = proposedHabit.vitalKind {
          HStack(spacing: 6) {
            Text("Helps with \(vitalKind.name)")
            Image(systemName: vitalKind.systemImage)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 0)

      VStack {
        if let previousQuantity = proposedHabit.displayPreviousQuantity, proposedHabit.shouldShowPreviousQuantity {
          Text("\(previousQuantity)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
            .contentTransition(.numericText(value: proposedHabit.previousValue ?? 0))
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
  }

  var recommendedValueDisplayView: some View {
    HStack(spacing: 4) {
      Image(systemName: "star.circle.fill")
      Text("Recommended")

      Spacer()

      Text(proposedHabit.displaySuggestedValue)
        .fontDesign(.rounded)
        .bold()
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.top, 4)
  }

  var setRecommendedValueButton: some View {
    Button {
      proposedHabit.value = proposedHabit.suggestedValue
    } label: {
      LabeledContent("Set Recommended Value") {
        Image(systemName: "star.circle.fill")
          .foregroundStyle(.primary)
          .bold()
      }
      .bold()
      .selectable()
      .padding()
    }
    .foregroundStyle(.white)
    .buttonStyle(.plain)
  }

  var alternateTargetMetricMenu: some View {
    Menu {
      ForEach(alternateTargetMetrics) { alternativeTargetMetric in
        Button {
          Task {
            // TODO: Select a different goal in the list.
//            proposedHabit = await habitsViewModel.generateProposedHabit(
//              for: alternativeTargetMetric,
//              vitalKind: proposedHabit.vitalKind
//            )
          }
        } label: {
          Label(alternativeTargetMetric.name, systemImage: alternativeTargetMetric.systemImage)
        }
      }
    } label: {
      LabeledContent("Change Habit") {
        Image(systemName: "trophy.fill")
          .foregroundStyle(.primary)
          .bold()
      }
      .bold()
      .selectable()
      .padding()
    }
    .foregroundStyle(.white)
    .buttonStyle(.plain)
  }

  var changeValueButton: some View {
    Button {
      presentedSheet = ProposedHabitTargetValueEditCardView(proposedHabit: $proposedHabit).tint(proposedHabit.targetMetric.color).asAny
    } label: {
      LabeledContent("Set Custom Value") {
        Image(systemName: "chart.xyaxis.line")
          .foregroundStyle(.primary)
          .bold()
      }
      .bold()
      .selectable()
      .padding()
    }
    .foregroundStyle(.white)
    .buttonStyle(.plain)
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 20) {
      ProposedHabitCell(
        proposedHabit: .constant(ProposedGoal(
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
        proposedHabit: .constant(ProposedGoal(
          habitID: nil,
          targetMetric: .walkingRunningDistance,
          value: 5,
          suggestedValue: 5,
          previousValue: 5,
          unitString: HKUnit.meterUnit(with: .kilo).unitString,
          vitalKind: .heartHealth,
          context: "You should run more.",
          hasUserEdited: true
        ))
      )
      ProposedHabitCell(
        proposedHabit: .constant(ProposedGoal(
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
}
