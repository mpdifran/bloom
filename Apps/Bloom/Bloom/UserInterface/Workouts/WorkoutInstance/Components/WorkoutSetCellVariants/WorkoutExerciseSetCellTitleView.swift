//
//  WorkoutExerciseSetCellTitleView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-07.
//

import SwiftUI
import DataContainer
import SFSafeSymbols

struct WorkoutExerciseSetCellTitleView: View {
  let symbol: SFSymbol
  let title: String
  let measurementDescription: String
  let measurementSubtitle: String?
  let mode: WorkoutExerciseSetCell.Mode
  let isPeeking: Bool

  init(
    symbol: SFSymbol,
    title: String,
    measurementDescription: String,
    measurementSubtitle: String? = nil,
    mode: WorkoutExerciseSetCell.Mode,
    isPeeking: Bool
  ) {
    self.symbol = symbol
    self.title = title
    self.measurementDescription = measurementDescription
    self.measurementSubtitle = measurementSubtitle
    self.mode = mode
    self.isPeeking = isPeeking
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack(alignment: .bottom) {
          if mode == .current || mode == .upNext || isPeeking {
            Image(systemSymbol: symbol)
              .font(.largeTitle)
            if let measurementSubtitle {
              Text(measurementSubtitle)
                .font(.caption)
            }
          }
        }

        Text(title)
      }

      Spacer()

      Text(measurementDescription)
        .monospacedDigit()
        .contentTransition(.numericText())
    }
    .font(.title2)
    .bold()
  }
}

#Preview {
  WorkoutExerciseSetCellTitleView(
    symbol: .figureRun,
    title: "Run",
    measurementDescription: "200 m",
    mode: .current,
    isPeeking: false
  )
}
