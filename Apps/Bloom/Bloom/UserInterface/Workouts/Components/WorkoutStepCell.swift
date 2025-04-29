//
//  WorkoutStepCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import AppUI
import SFSafeSymbols
import HealthKit

extension WorkoutStepCell {
  enum State {
    case complete
    case current
    case upcoming
  }
}

struct WorkoutStepCell: View {
  let step: WorkoutStep
  let state: State
  let currentTime: TimeInterval

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(step.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)


        HStack(spacing: 4) {
          if let duration = step.durationDescription {
            Text(duration)
          }
          if let reps = step.numberOfReps {
            Text("•")
            Text("\(reps) Reps")
          }
          if let distanceQuantity = step.distanceQuantity, let unit = step.distanceUnit {
            Text("•")
            Text(distanceQuantity.displayString(for: unit.hkUnit))
          }
        }
      }

      Spacer()

      if state != .upcoming {
        Text(timeString)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .monospacedDigit()
      }

      if state == .current {
        Image(systemSymbol: workoutSymbol)
          .font(.title)
          .bold()
      }
    }
    .foregroundStyle(textColor)
    .cardContainer(fill: containerBackground)
    .animation(.default, value: state)
  }
}

private extension WorkoutStepCell {

  var workoutSymbol: SFSymbol {
    if let overrideWorkoutType = step.overrideAppleWorkoutType {
      return SFSymbol(rawValue: overrideWorkoutType.systemImage)
    }

    if let workoutType = step.workoutTemplate?.appleWorkoutType {
      return SFSymbol(rawValue: workoutType.systemImage)
    }

    return SFSymbol(rawValue: HKWorkoutActivityType.other.systemImage)
  }

  var timeString: String {
    let totalMilliseconds = Int(currentTime * 1000)
    let minutes = totalMilliseconds / 60000
    let seconds = (totalMilliseconds % 60000) / 1000
    let milliseconds = (totalMilliseconds % 1000) / 100
    return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
  }

  var textColor: some ShapeStyle {
    switch state {
    case .complete:
      AnyShapeStyle(.secondary)
    case .current:
      AnyShapeStyle(.invertedText)
    case .upcoming:
      AnyShapeStyle(.text)
    }
  }

  var containerBackground: some ShapeStyle {
    switch state {
    case .complete:
      AnyShapeStyle(.background.secondary)
    case .current:
      AnyShapeStyle(.green)
    case .upcoming:
      AnyShapeStyle(.background)
    }
  }
}

#Preview {
  @Previewable @State var selectedIndex = 0

  PreviewEnvironment {
    BloomScrollView {
      ForEachEnumerated(WorkoutTemplate.Preview.deadlifts.steps ?? []) { index, step in
        if index >= selectedIndex {
          WorkoutStepCell(
            step: step,
            state: state(for: index, selectedIndex: selectedIndex),
            currentTime: 134.2
          )
        }
      }
    }
    .animation(.default, value: selectedIndex)
    .shelf {
      Button {
        selectedIndex += 1
        if selectedIndex == (WorkoutTemplate.Preview.deadlifts.steps ?? []).count {
          selectedIndex = 0
        }
      } label: {
        Text("Toggle")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .tint(.green)
    }
  }
}


private func state(for index: Int, selectedIndex: Int) -> WorkoutStepCell.State {
  if index < selectedIndex {
    .complete
  } else if index == selectedIndex {
    .current
  } else {
    .upcoming
  }
}
