//
//  WorkoutExerciseDetailsRestCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI

struct WorkoutExerciseDetailsRestCell: View {
  let restDuration: Double

  var body: some View {
    HStack {
      Text("Rest")
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      Text(restDescription)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.headline)
    .bold()
    .fontDesign(.rounded)
  }
}

private extension WorkoutExerciseDetailsRestCell {

  var restDescription: String {
    DateFormatter.timeIntervalHourMinuteSecondAbbreviated.string(from: DateComponents(second: Int(restDuration))) ?? ""
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      WorkoutExerciseDetailsRestCell(restDuration: 60)
    }
  }
}
