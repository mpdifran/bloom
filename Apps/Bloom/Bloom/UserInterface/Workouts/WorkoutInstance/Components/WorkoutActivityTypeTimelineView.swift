//
//  WorkoutActivityTypeTimelineView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI
import HealthKit
import SFSafeSymbols
import AppUI

private extension CGFloat {
  static let dimension: CGFloat = 35
  static let smallDimension: CGFloat = 25
}

struct WorkoutActivityTypeTimelineView: View {
  let activityTypes: [HKWorkoutActivityType]
  let currentIndex: Int

  var body: some View {
    HStack {
      ForEachEnumeratedNoID(activityTypes) { (index, activityType) in
        if index != 0 {
          Spacer()
        }

        Circle()
          .fill(index <= currentIndex ? AnyShapeStyle(.tint) : AnyShapeStyle(.background.secondary))
          .frame(square: index == currentIndex ? .dimension : .smallDimension)
          .overlay(
            Image(systemSymbol: SFSymbol(rawValue: activityType.systemImage))
              .font(.system(size: index == currentIndex ? .dimension / 2 : .smallDimension / 2))
              .foregroundStyle(index <= currentIndex ? AnyShapeStyle(.invertedText) : AnyShapeStyle(.fill))
          )
          .opacity(index < currentIndex ? 0.5 : 1)
      }
    }
    .frame(height: .dimension)
    .tint(.green)
    .animation(.bouncy, value: currentIndex)
  }
}

#Preview {
  @Previewable @State var currentIndex = 0

  PreviewEnvironment {
    VStack {
      Spacer()
      WorkoutActivityTypeTimelineView(
        activityTypes: [
          .preparationAndRecovery,
          .traditionalStrengthTraining,
          .cycling,
          .cooldown
        ],
        currentIndex: 2
      )

      Spacer()

      WorkoutActivityTypeTimelineView(
        activityTypes: [
          .preparationAndRecovery,
          .traditionalStrengthTraining,
          .rowing,
          .cycling,
          .cooldown
        ],
        currentIndex: currentIndex
      )
      Spacer()
    }
    .shelf {
      Button {
        currentIndex = (currentIndex + 1) % 5
      } label: {
        Text("Advance")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
      .tint(.green)
    }
  }
}
