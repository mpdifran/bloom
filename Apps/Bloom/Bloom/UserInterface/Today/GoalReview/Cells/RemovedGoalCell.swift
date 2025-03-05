//
//  RemovedGoalCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-05.
//

import SwiftUI
import HealthKit
import DataContainer

struct RemovedGoalCell: View {
  let proposedGoal: ProposedGoal
  let includeActions: Bool
  let addBack: () -> Void

  init(
    proposedGoal: ProposedGoal,
    includeActions: Bool = true,
    addBack: @escaping () -> Void
  ) {
    self.proposedGoal = proposedGoal
    self.includeActions = includeActions
    self.addBack = addBack
  }

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack {
        habitContentView
      }
      .cardContainer()
      .padding(4)

      if includeActions {
        Text("This goal will be removed")
          .foregroundStyle(.white)
          .bold()
          .fixedSize(horizontal: false, vertical: true)
          .padding()

        Divider()

        addBackButton
      }
    }
    .cardContainer(fill: .tint, includePadding: false, cornerRadius: 30)
    .animation(.default, value: proposedGoal.value)
    .tint(.gray)
  }
}

private extension RemovedGoalCell {

  var habitContentView: some View {
    HStack {
      Image(systemName: proposedGoal.targetMetric.systemImage)
        .font(.title)
        .foregroundStyle(.tint)

      VStack(alignment: .leading) {
        Text(proposedGoal.targetMetric.name)
          .bold()
      }

      Spacer(minLength: 0)

      VStack {
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

  var addBackButton: some View {
    Button {
      addBack()
    } label: {
      LabeledContent("Add Back") {
        Image(systemName: "arrow.uturn.up.circle.fill")
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
    context: "This goal will be removed.",
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
    context: "This goal will be removed.",
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
    context: "This goal will be removed.",
    hasUserEdited: false
  )

  ScrollView {
    VStack(spacing: 20) {
      RemovedGoalCell(proposedGoal: waterGoal) { }
      RemovedGoalCell(proposedGoal: walkingGoal) { }
      RemovedGoalCell(proposedGoal: daylightGoal) { }
    }
    .padding()
  }
}
