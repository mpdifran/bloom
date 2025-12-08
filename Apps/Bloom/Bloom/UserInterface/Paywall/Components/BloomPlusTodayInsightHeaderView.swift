//
//  BloomPlusTodayInsightHeaderView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-03.
//

import SwiftUI
import BloomUI

struct BloomPlusTodayInsightHeaderView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      BloomPlusLogo()
        .horizontallyCentered()

      Text("Feel Better, One Day at a Time")
        .font(.largeTitle)
        .bold()
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)

      Text("Get simple, personalized insights each morning to help you move, rest, and eat with intention.")
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
    }
    .multilineTextAlignment(.leading)
    .horizontalAlignment(.leading)
  }
}

#Preview {
  BloomPlusTodayInsightHeaderView()
}
