//
//  WorkoutTemplateCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-28.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct WorkoutTemplateCell: View {
  let workoutTemplate: WorkoutTemplate

  var body: some View {
    HStack(spacing: 20) {
      WorkoutTemplateIconView(workoutTemplate: workoutTemplate)

      VStack(alignment: .leading) {
        Text(workoutTemplate.title)
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.leading)
          .lineLimit(2)

        Text(workoutTemplate.durationDescription)
          .foregroundStyle(.secondary)
          .font(.subheadline)
          .lineLimit(2)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      WorkoutTemplateCell(workoutTemplate: .Preview.deadlifts)
    }
  }
}
