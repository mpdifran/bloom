//
//  MonitorsTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI

struct MonitorsTabView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "waveform.path.ecg")
        .font(.largeTitle)
        .foregroundStyle(.red)

      Text("Monitors")
        .font(.headline)
        .fontDesign(.rounded)

      Text("Coming Soon")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  MonitorsTabView()
}
