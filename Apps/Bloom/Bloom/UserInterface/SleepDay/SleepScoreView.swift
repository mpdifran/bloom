//
//  SleepScoreView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct SleepScoreView: View {
  let score: Int?
  let isMini: Bool

  init(score: Int?, isMini: Bool = false) {
    self.score = score
    self.isMini = isMini
  }

  var body: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: .moonStarsFill)
      if let score {
        Text(verbatim: "\(score)")
          .contentTransition(.numericText(value: Double(score)))
      } else {
        Text(verbatim: "--")
      }
    }
    .font(isMini ? .title2 : .system(size: 50))
    .bold()
    .fontDesign(.rounded)
    .foregroundStyle(.white)
    .minimumScaleFactor(0.3)
    .lineLimit(1)
    .padding(.leading, 2)
    .padding(.trailing, 8)
    .padding(.vertical, 2)
    .background {
      Capsule()
        .fill(
          LinearGradient(
            colors: [.deepSleep, .coreSleep],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
    }
    .animation(.default, value: score)
  }
}

#Preview {
  PreviewEnvironment {
    List {
      SleepScoreView(score: 93)
      SleepScoreView(score: 100)
      SleepScoreView(score: 13)
      SleepScoreView(score: nil)
      SleepScoreView(score: 56, isMini: true)
    }
    .listStyle(.plain)
  }
}
