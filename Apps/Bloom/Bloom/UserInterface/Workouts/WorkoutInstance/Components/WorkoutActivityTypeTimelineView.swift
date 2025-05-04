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
}

struct WorkoutActivityTypeTimelineView: View {
  let activityTypes: [HKWorkoutActivityType]
  let currentIndex: Int

  var body: some View {
    ZStack {
      lineView

      HStack {
        ForEachEnumeratedNoID(activityTypes) { (index, activityType) in
          if index != 0 {
            Spacer()
          }

          Circle()
            .fill(index <= currentIndex ? AnyShapeStyle(.tint) : AnyShapeStyle(.background.secondary))
            .frame(width: .dimension, height: .dimension)
            .overlay(
              Image(systemSymbol: SFSymbol(rawValue: activityType.systemImage))
                .font(.system(size: .dimension / 2))
                .foregroundStyle(index <= currentIndex ? AnyShapeStyle(.invertedText) : AnyShapeStyle(.fill))
            )
        }
      }
    }
    .frame(height: .dimension)
    .tint(.green)
    .animation(.easeOut, value: currentIndex)
  }
}

private extension WorkoutActivityTypeTimelineView {

  var lineView: some View {
    GeometryReader { proxy in
      VStack {
        Spacer()
        Rectangle()
          .fill(.background.secondary)
          .frame(height: 4)
          .overlay {
            Rectangle()
              .fill(.tint)
              .frame(width: proxy.size.width * CGFloat(currentIndex) / CGFloat(activityTypes.count - 1))
              .horizontalAlignment(.leading)
          }
        Spacer()
      }
    }
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
