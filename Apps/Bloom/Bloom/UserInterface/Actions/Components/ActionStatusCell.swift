//
//  ActionStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-07.
//

import SwiftUI
import SFSafeSymbols
import AppUI

struct ActionStatusCell: View {
  let title: String
  let symbol: SFSymbol
  let latestValue: String?
  let latestTimestamp: String?

  var body: some View {
    HStack {

      VStack(alignment: .leading) {
        HStack {
          Image(systemSymbol: symbol)
          Text(title)
            .minimumScaleFactor(0.4)
            .lineLimit(1)
        }
        .font(.caption)
        .bold()
        .fontDesign(.rounded)


        Text(latestValue ?? "No Data")
          .font(.body)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(.tint)
          .lineLimit(1)

        Group {
          if let latestTimestamp {
            Text(latestTimestamp)
          } else {
            Text("Never")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }

      Spacer()
    }
    .cardContainer(fill: .tint.quinary, stroke: .tint.quaternary)
  }
}

#Preview {
  ScrollView {
    VStack {
      HStack {
        ActionStatusCell(
          title: "Log Weight",
          symbol: .gaugeWithDotsNeedleBottom50percentBadgePlus,
          latestValue: "159.2 lbs",
          latestTimestamp: "Today"
        )
        .tint(.mutedIndigo)
        ActionStatusCell(
          title: "Log Blood Pressure",
          symbol: .gaugeOpenWithLinesNeedle67percentAndArrowtriangle,
          latestValue: "120/80",
          latestTimestamp: "Today"
        )
        .tint(.mutedPink)
      }
      HStack {
        ActionStatusCell(
          title: "Log Water",
          symbol: .waterbottleFill,
          latestValue: "500 mL",
          latestTimestamp: "Today"
        )
        .tint(.mutedBlue)
        Spacer()
      }
    }
    .horizontallyCentered()
    .padding()
  }
}
