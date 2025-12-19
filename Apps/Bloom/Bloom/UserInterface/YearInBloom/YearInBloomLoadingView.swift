//
//  YearInBloomLoadingView.swift
//  Bloom
//
//  Created by Claude on 2025-12-19.
//

import SwiftUI
import BloomUI
import AppUI

struct YearInBloomLoadingView: View {
  let year: Int

  var body: some View {
    VStack(spacing: 40) {
      Spacer()

      BudImage(.budThinking, dimension: 200)

      VStack(spacing: 16) {
        CircularSpinnerView()
          .foregroundStyle(.tint)

        Text("Crunching the numbers...")
          .font(.headline)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
      }

      VStack {
        Text("Year In Bloom")
          .font(.largeTitle)
          .bold()
          .fontDesign(.rounded)

        yearDigitsView
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .groupedBackground()
  }

  private var yearDigitsView: some View {
    let digits = String(year).map { String($0) }
    let rotations: [Double] = [7, -8, 6, -9]
    let colors: [Color] = [
      .teal.opacity(0.9),
      .green.opacity(0.8),
      .mint.opacity(0.85),
      .cyan.opacity(0.75)
    ]

    return HStack(spacing: -16) {
      ForEach(Array(digits.enumerated()), id: \.offset) { index, digit in
        Text(digit)
          .font(.system(size: 100))
          .fontWeight(.black)
          .fontDesign(.rounded)
          .foregroundStyle(colors[index % colors.count])
          .rotationEffect(.degrees(rotations[index % rotations.count]))
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    YearInBloomLoadingView(year: 2025)
  }
}
