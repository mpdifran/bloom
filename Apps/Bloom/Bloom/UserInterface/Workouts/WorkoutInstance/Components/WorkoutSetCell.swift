//
//  WorkoutSetCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import AppUI
import SFSafeSymbols
import HealthKit

extension WorkoutSetCell {
  enum State {
    case complete
    case current
    case upcoming
  }
}

struct WorkoutSetCell: View {
  let set: WorkoutSet
  let state: State
  let currentTime: TimeInterval

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(set.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)


        HStack(spacing: 4) {
          Text(set.durationDescription)
          Text("•")
          Text("\(set.numberOfSets) Sets")
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
        Image(systemSymbol: SFSymbol(rawValue: set.appleWorkoutType.systemImage))
          .font(.title)
          .bold()
      }
    }
    .foregroundStyle(textColor)
    .cardContainer(fill: containerBackground, stroke: borderStyle)
    .animation(.default, value: state)
  }
}

private extension WorkoutSetCell {

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
      AnyShapeStyle(.background)
    case .current:
      AnyShapeStyle(.green)
    case .upcoming:
      AnyShapeStyle(.background)
    }
  }

  var borderStyle: some ShapeStyle {
    switch state {
    case .complete:
      AnyShapeStyle(.fill)
    case .current:
      AnyShapeStyle(.clear)
    case .upcoming:
      AnyShapeStyle(.clear)
    }
  }
}

#Preview {
  @Previewable @State var selectedIndex = 0

  PreviewEnvironment {
    BloomScrollView {
      ForEachEnumerated(WorkoutPlan.Preview.deadlifts.orderedSets) { index, set in
        WorkoutSetCell(
          set: set,
          state: state(for: index, selectedIndex: selectedIndex),
          currentTime: 134.2
        )
      }
    }
    .animation(.default, value: selectedIndex)
    .shelf {
      Button {
        selectedIndex += 1
        if selectedIndex == (WorkoutPlan.Preview.deadlifts.orderedSets).count {
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


private func state(for index: Int, selectedIndex: Int) -> WorkoutSetCell.State {
  if index < selectedIndex {
    .complete
  } else if index == selectedIndex {
    .current
  } else {
    .upcoming
  }
}
