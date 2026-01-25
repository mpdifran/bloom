//
//  TodayTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI

struct TodayTabView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "sun.max.fill")
        .font(.largeTitle)
        .foregroundStyle(.yellow)

      Text("Today")
        .font(.headline)
        .fontDesign(.rounded)

      Text("Coming Soon")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  TodayTabView()
}
