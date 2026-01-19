//
//  BloomPlusMonitorHeaderView.swift
//  Bloom
//

import SwiftUI
import BloomUI

struct BloomPlusMonitorHeaderView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      BloomPlusLogo()
        .horizontallyCentered()

      Text("Stay Ahead of How You Feel")
        .font(.largeTitle)
        .bold()
        .fontDesign(.rounded)
        .fixedSize(horizontal: false, vertical: true)
        .horizontalAlignment(.leading)

      Text("Bloom learns your baselines for stress, recovery, and sleep, then alerts you when something's off.")
        .foregroundStyle(.secondary)
        .horizontalAlignment(.leading)
    }
    .multilineTextAlignment(.leading)
    .horizontalAlignment(.leading)
  }
}

#Preview {
  BloomPlusMonitorHeaderView()
}
