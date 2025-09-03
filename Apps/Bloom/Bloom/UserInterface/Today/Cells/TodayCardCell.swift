//
//  TodayCardCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import SFSafeSymbols

struct TodayCardCell: View {
  let symbol: SFSymbol
  let title: String
  let content: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView

      Text(content)
        .font(.body)
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
    }
    .foregroundStyle(.white)
    .horizontallyCentered()
    .cardContainer(fill: color.gradient)
  }
}

private extension TodayCardCell {

  @ViewBuilder
  var headerView: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title3)
        .foregroundStyle(color)
        .frame(square: 30)
        .padding(6)
        .background {
          RoundedRectangle(cornerRadius: 13)
            .fill(.white)
        }

      Text(title)
        .font(.title3)
        .fontDesign(.rounded)
        .bold()

      Spacer()
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TodayCardCell(
        symbol: .sunHorizonFill,
        title: "Today's Advice",
        content: "Fit in at least 20 minutes of moderate cardio today—go for a brisk bike ride or jog—to boost your weekly cardio minutes and support your VO2 max goal.",
        color: .mutedOrange
      )
    }
  }
}
