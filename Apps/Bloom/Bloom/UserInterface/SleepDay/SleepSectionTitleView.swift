//
//  SleepSectionTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-11.
//

import SFSafeSymbols
import SwiftUI

struct SleepSectionTitleView: View {
  let title: String
  let symbol: SFSymbol
  let isMulticolor: Bool

  init(
    title: String,
    symbol: SFSymbol,
    isMulticolor: Bool = false
  ) {
    self.title = title
    self.symbol = symbol
    self.isMulticolor = isMulticolor
  }

  var body: some View {
    HStack {
      if isMulticolor {
        Image(systemSymbol: symbol)
          .foregroundStyle(.white, .tint)
      } else {
        Image(systemSymbol: symbol)
          .foregroundStyle(.tint)
      }

      Text(title)

      Spacer()
    }
    .font(.title2)
    .bold()
    .fontDesign(.rounded)
  }
}

#Preview {
  List {
    SleepSectionTitleView(
      title: "Heart Rate",
      symbol: .heartFill
    )
  }
  .listStyle(.plain)
}
