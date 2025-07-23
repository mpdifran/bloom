//
//  MorningReportAlertCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI
import SFSafeSymbols

struct MorningReportAlertCell<Icon: View>: View {
  let title: String
  let message: String
  let iconBuilder: () -> Icon

  init(
    title: String,
    message: String,
    @ViewBuilder iconBuilder: @escaping () -> Icon,
  ) {
    self.title = title
    self.message = message
    self.iconBuilder = iconBuilder
  }

  var body: some View {
    HStack(spacing: 14) {
      iconBuilder()
        .frame(height: 40)

      VStack(alignment: .leading) {
        Text(title)
          .bold()
          .font(.caption)
          .lineLimit(1)
        Text(message)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      .fontDesign(.rounded)

      Spacer(minLength: 0)
    }
    .frame(width: 250)
    .padding(.horizontal, 20)
    .padding(.vertical, 8)
    .background {
      Capsule()
        .fill(.tint.quaternary)
    }
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView(padding: .vertical) {
      ScrollView(.horizontal) {
        HStack {
          MorningReportAlertCell(
            title: "Late Period",
            message: "Your period was predicted to start yesterday.",
            iconBuilder: {
              DayCapsule(
                dayNumber: "",
                highlightKind: .partial,
                isToday: false
              )
            }
          )
          .tint(.mutedPink)

          MorningReportAlertCell(
            title: "Sedentary",
            message: "You've been sedentary for 3 days in a row.",
            iconBuilder: {
              Image(systemSymbol: .figureStand)
                .font(.title)
                .foregroundStyle(.tint)
            }
          )
          .tint(.mutedYellow)
        }
        .padding(.horizontal)
      }
      .scrollIndicators(.hidden)
    }
  }
}
