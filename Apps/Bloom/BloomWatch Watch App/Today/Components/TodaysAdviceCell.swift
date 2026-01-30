//
//  TodaysAdviceCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-30.
//

import SwiftUI
import SFSafeSymbols

struct TodaysAdviceCell: View {
  let advice: String

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(.white)
          .frame(square: 30)
          .overlay {
            Image(systemSymbol: .sunriseFill)
              .foregroundStyle(.mutedOrange)
          }

        Text("Today's Advice")
          .bold()
      }
      .font(.headline)

      Text(advice)
        .font(.footnote)
    }
    .listRowBackground(
      RoundedRectangle(cornerRadius: 16)
        .fill(.mutedOrange.gradient)
    )
  }
}

#Preview {
  PreviewEnvironment {
    List {
      TodaysAdviceCell(advice: "Prioritize active recovery today: choose light aerobic movement like a 20-30 minute easy bike or walk.")
    }
  }
}
