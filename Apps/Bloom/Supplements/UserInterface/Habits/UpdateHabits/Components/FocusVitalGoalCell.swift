//
//  FocusVitalGoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-11.
//

import SwiftUI
import DataContainer

struct FocusVitalGoalCell: View {
  @Binding var focusVital: FocusVital
  let includeActions: Bool

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
      .cardContainer(fill: .background.secondary)
      .padding(4)

      if includeActions {
        if let context = proposedGoal.context, context.isNotEmpty {
          contextView(context: context)
          Divider()
        }

        if remainingGoals.isNotEmpty {
          alternateGoalMenu
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
    .animation(.default, value: proposedGoal)
    .tint(proposedGoal.targetMetric.color)
    .sheet($presentedSheet)
  }
}

private extension FocusVitalGoalCell {

  var proposedGoal: ProposedGoal {
    focusVital.proposedGoals.first! // TODO: This is a little unsafe!
  }

  var remainingGoals: [ProposedGoal] {
    focusVital.proposedGoals.filter {
      $0 != proposedGoal
    }
  }
}

private extension FocusVitalGoalCell {

  var habitContentView: some View {
    HStack {
      Image(systemName: proposedGoal.targetMetric.systemImage)
        .font(.title)
        .foregroundStyle(.tint)

      VStack(alignment: .leading) {
        Text(proposedGoal.targetMetric.name)
          .bold()

        if let vitalKind = proposedGoal.vitalKind {
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
        if let previousQuantity = proposedGoal.displayPreviousQuantity, proposedGoal.shouldShowPreviousQuantity {
          Text("\(previousQuantity)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
            .contentTransition(.numericText(value: proposedGoal.previousValue ?? 0))
          Image(systemName: "arrow.down")
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
      Image(systemName: "star.circle.fill")
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

  func contextView(context: String) -> some View {
    Text(context)
      .foregroundStyle(.white)
      .bold()
      .fixedSize(horizontal: false, vertical: true)
      .padding()
  }

  var alternateGoalMenu: some View {
    Menu {
      ForEach(remainingGoals) { goal in
        Button {
          focusVital.proposedGoals.removeAll(where: { $0 == goal })
          focusVital.proposedGoals.insert(goal, at: 0)
        } label: {
          Label(goal.targetMetric.name, systemImage: goal.targetMetric.systemImage)
        }
      }
    } label: {
      LabeledContent("Change Goal") {
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

  var setRecommendedValueButton: some View {
    Button {
      focusVital.proposedGoals[0].value = proposedGoal.suggestedValue
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

  var changeValueButton: some View {
    Button {
      presentedSheet = ProposedHabitTargetValueEditCardView(proposedHabit: $focusVital.proposedGoals[0])
        .tint(proposedGoal.targetMetric.color)
        .asAny
    } label: {
      LabeledContent("Change Value") {
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
  @Previewable @State var focusVital = FocusVital(
    vitalKind: .activityLevel,
    proposedGoals: [
      .init(
        habitID: nil,
        targetMetric: .bikeDistance,
        value: 10,
        suggestedValue: 10,
        previousValue: 5,
        unitString: "km",
        vitalKind: .activityLevel,
        context: "Biking can help improve your activity level.",
        hasUserEdited: false
      ),
      .init(
        habitID: nil,
        targetMetric: .runDistance,
        value: 10,
        suggestedValue: 12,
        previousValue: 5,
        unitString: "km",
        vitalKind: .activityLevel,
        context: "Running can help improve your activity level.",
        hasUserEdited: true
      )
    ]
  )

  FocusVitalGoalCell(
    focusVital: $focusVital,
    includeActions: true
  )
  .padding()
}
