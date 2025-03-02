//
//  SleepProgramSectionHeader.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SFSafeSymbols
import SwiftUI

struct SleepProgramSectionHeader: View {
  let title: String
  let subtitle: String
  let symbol: SFSymbol
  let isMulticolored: Bool

  init(
    title: String,
    subtitle: String,
    symbol: SFSymbol,
    isMulticolored: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.symbol = symbol
    self.isMulticolored = isMulticolored
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
          .font(.title)
          .bold()
          .fontDesign(.rounded)

        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Image(systemSymbol: symbol)
        .font(.system(size: 40))
        .if(isMulticolored) {
          $0.foregroundStyle(.white, .tint)
        }
        .if(!isMulticolored) {
          $0.foregroundStyle(.tint)
        }

    }
    .zStackAlignment(.center)
  }
}

#Preview {
  List {
    SleepProgramSectionHeader(
      title: "Workouts",
      subtitle: "Last Two Weeks",
      symbol: .figureRun
    )
    .tint(.green)

    SleepProgramSectionHeader(
      title: "Resting Heart Rate",
      subtitle: "Last Two Weeks",
      symbol: .arrowDownHeartFill,
      isMulticolored: true
    )
    .tint(.pink)
  }
}
