//
//  HeartRateValueEditView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-05.
//

import SwiftUI
import CoreHealth

struct HeartRateValueEditView: View {
  let title: LocalizedStringKey
  @Binding var value: Double
  let range: ClosedRange<Double>

  @State private var localValue: Double = 0
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(spacing: 16) {
      Text(verbatim: "\(Int(localValue))")
        .font(.system(size: 48, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.mutedPink)

      Text("bpm")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .focusable()
    .focused($isFocused)
    .digitalCrownRotation($localValue, from: range.lowerBound, through: range.upperBound, by: 1, sensitivity: .low)
    .navigationTitle(title)
    .onAppear {
      localValue = value
      isFocused = true
    }
    .onDisappear {
      value = localValue
    }
  }
}

#Preview {
  NavigationStack {
    HeartRateValueEditView(
      title: "Max HR",
      value: .constant(185),
      range: 120...220
    )
  }
}
