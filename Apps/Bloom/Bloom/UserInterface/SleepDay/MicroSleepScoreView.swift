//
//  MicroSleepScoreView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-21.
//

import SwiftUI
import BloomFoundation

struct MicroSleepScoreView: View {
  let score: Int?

  var body: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: .moonStarsFill)
      if let score {
        Text("\(score)")
          .contentTransition(.numericText(value: Double(score)))
      } else {
        Text("--")
      }
    }
    .font(.title3)
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
    .frame(height: 30)
    .animation(.default, value: score)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack {
        MicroSleepScoreView(score: 85)
        MicroSleepScoreView(score: 72)
        MicroSleepScoreView(score: nil)
      }
    }
  }
}
