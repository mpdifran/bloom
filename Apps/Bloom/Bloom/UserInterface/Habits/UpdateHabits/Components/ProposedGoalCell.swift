//
//  ProposedGoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-11.
//

import SFSafeSymbols
import SwiftUI
import HealthKit
import DataContainer

struct ProposedGoalCell: View {
  @Binding var proposedGoal: ProposedGoal
  let includeActions: Bool

  init(
    proposedGoal: Binding<ProposedGoal>,
    includeActions: Bool = true
  ) {
    self._proposedGoal = proposedGoal
    self.includeActions = includeActions
  }

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  @State private var presentedSheet: AnyView?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack {
        habitContentView

        if proposedGoal.shouldShowSuggestedValue {
          Divider()
          recommendedValueDisplayView
        }
      }
      .cardContainer()
      .padding(4)

      if includeActions {
        if let context = proposedGoal.context, context.isNotEmpty {
          Text(context)
            .foregroundStyle(.white)
            .bold()
            .fixedSize(horizontal: false, vertical: true)
            .padding()

          Divider()
        }

        if proposedGoal.shouldShowSuggestedValue {
          setRecommendedValueButton
          Divider()
        }

        changeValueButton
      }
    }
    .cardContainer(fill: .tint, includePadding: false, cornerRadius: 30)
    .animation(.default, value: proposedGoal.value)
    .tint(proposedGoal.targetMetric.color)
    .sheet($presentedSheet)
  }
}

private extension ProposedGoalCell {

  var habitContentView: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: proposedGoal.targetMetric.systemImage))
        .font(.title)
        .foregroundStyle(.tint)

      VStack(alignment: .leading) {
        Text(proposedGoal.targetMetric.name)
          .bold()
      }

      Spacer(minLength: 0)

      VStack {
        if let previousQuantity = proposedGoal.displayPreviousQuantity, proposedGoal.shouldShowPreviousQuantity {
          Text("\(previousQuantity)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
            .contentTransition(.numericText(value: proposedGoal.previousValue ?? 0))
          Image(systemSymbol: .arrowDown)
            .font(.caption)
            .foregroundStyle(.secondary)
        } else if proposedGoal.isNewHabit {
          Text("NEW")
            .foregroundStyle(.mutedRed)
            .bold()
            .font(.caption)
        }

        Text(proposedGoal.displayQuantity)
          .font(.title3)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.tint)
          .contentTransition(.numericText(value: proposedGoal.value))
          .animation(.default, value: proposedGoal.value)
      }
    }
  }

  var recommendedValueDisplayView: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: .starCircleFill)
      Text("Recommended")

      Spacer()

      Text(proposedGoal.displaySuggestedValue)
        .fontDesign(.rounded)
        .bold()
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.top, 4)
  }

  var setRecommendedValueButton: some View {
    Button {
      proposedGoal.value = proposedGoal.suggestedValue
    } label: {
      LabeledContent("Set Recommended Value") {
        Image(systemSymbol: .starCircleFill)
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
      presentedSheet = ProposedHabitTargetValueEditCardView(proposedHabit: $proposedGoal)
        .tint(proposedGoal.targetMetric.color)
        .asAny
    } label: {
      LabeledContent("Change Value") {
        Image(systemSymbol: .chartXyaxisLine)
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
  @Previewable @State var waterGoal = ProposedGoal(
    habitID: nil,
    targetMetric: .waterIntake,
    value: 500,
    suggestedValue: 800,
    previousValue: 250,
    unitString: HKUnit.literUnit(with: .milli).unitString,
    vitalKind: .nutrition,
    context: "Water can keep you hydrated.",
    hasUserEdited: true
  )

  @Previewable @State var walkingGoal = ProposedGoal(
    habitID: nil,
    targetMetric: .walkingRunningDistance,
    value: 5,
    suggestedValue: 5,
    previousValue: 5,
    unitString: HKUnit.meterUnit(with: .kilo).unitString,
    vitalKind: .heartHealth,
    context: "You should run more.",
    hasUserEdited: true
  )

  @Previewable @State var daylightGoal = ProposedGoal(
    habitID: nil,
    targetMetric: .timeInDaylight,
    value: 30,
    suggestedValue: 30,
    previousValue: nil,
    unitString: HKUnit.minute().unitString,
    vitalKind: .sleepQuality,
    context: "Get out in the sun!",
    hasUserEdited: false
  )

  ScrollView {
    VStack(spacing: 20) {
      ProposedGoalCell(proposedGoal: $waterGoal)
      ProposedGoalCell(proposedGoal: $walkingGoal)
      ProposedGoalCell(proposedGoal: $daylightGoal)
    }
    .padding()
  }
}
