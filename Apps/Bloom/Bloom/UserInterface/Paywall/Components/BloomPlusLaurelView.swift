//
//  BloomPlusLaurelView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-18.
//

import SFSafeSymbols
import SwiftUI

struct BloomPlusLaurelView: View {
  let title: String

  var body: some View {
    HStack {
      Image(systemSymbol: .laurelLeading)
        .font(.largeTitle)

      Text(title)
        .multilineTextAlignment(.center)
        .bold()

      Image(systemSymbol: .laurelTrailing)
        .font(.largeTitle)
    }
    .bold()
    .frame(maxWidth: 160)
  }
}

#Preview {
  BloomPlusLaurelView(title: "Best Health App 2025")
}
