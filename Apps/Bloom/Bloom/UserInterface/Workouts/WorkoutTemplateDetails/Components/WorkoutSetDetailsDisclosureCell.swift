//
//  WorkoutSetDetailsDisclosureCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct WorkoutSetDetailsDisclosureCell: View {
  let set: WorkoutSet

  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      content
    } label: {
      label
    }
    .disclosureGroupStyle(WorkoutSetDetailsDisclosureGroupStyle())
  }
}

private extension WorkoutSetDetailsDisclosureCell {

  var label: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: set.appleWorkoutType.systemImage))
        .foregroundStyle(.green)
        .font(.largeTitle)
        .frame(width: 60)

      VStack(alignment: .leading) {
        Text(set.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Text("\(set.format.name) • \(set.setsDescription) • \(set.exercisesCountDescription)")
          .font(.subheadline)
          .fixedSize(horizontal: false, vertical: true)

        Text(set.focus)
          .lineLimit(3)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .lineLimit(2)

      Spacer()
    }
  }

  var content: some View {
    VStack(alignment: .leading) {
      ForEach(set.exercises ?? []) { exercise in
        Divider()

        WorkoutExerciseDetailsCell(exercise: exercise)

        if set.restBetweenExercises > 0 {
          Divider()

          WorkoutExerciseDetailsRestCell(restDuration: set.restBetweenExercises)
        }
      }
    }
  }
}

private struct WorkoutSetDetailsDisclosureGroupStyle: DisclosureGroupStyle {
  @State private var selectionToggle = false

  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        configuration.label
        Spacer()
        Image(systemSymbol: .chevronDown)
          .fontDesign(.rounded)
          .rotationEffect(.degrees(configuration.isExpanded ? -180 : 0))
      }
      .selectable()
      .onTapGesture {
        withAnimation {
          configuration.isExpanded.toggle()
        }
        selectionToggle.toggle()
      }

      if configuration.isExpanded {
        configuration.content
      }
    }
    .clipped()
    .animation(.easeInOut, value: configuration.isExpanded)
    .cardContainer()
    .sensoryFeedback(.selection, trigger: selectionToggle)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ForEach(WorkoutPlan.Preview.deadlifts.sets ?? []) { set in
        WorkoutSetDetailsDisclosureCell(set: set)
      }
    }
  }
}
